defmodule Protox.DefineEncoder do
  @moduledoc false
  # Internal. Generates the encoder of a message.

  def define(fields, required_fields, syntax, opts \\ []) do
    {keep_unknown_fields, _opts} = Keyword.pop(opts, :keep_unknown_fields, true)

    {oneofs, fields_without_oneofs} = Protox.Defs.split_oneofs(fields)

    encode_fun = make_encode_fun(oneofs, fields_without_oneofs, keep_unknown_fields)
    encode_oneof_funs = make_encode_oneof_funs(oneofs)
    encode_field_funs = make_encode_field_funs(fields, required_fields, syntax)
    encode_unknown_fields_fun = make_encode_unknown_fields_fun(keep_unknown_fields)

    quote do
      unquote(encode_fun)

      unquote(encode_oneof_funs)
      unquote(encode_field_funs)
      unquote(encode_unknown_fields_fun)
    end
  end

  defp make_encode_fun(oneofs, fields, keep_unknown_fields) do
    ast = quote do: []
    ast = make_encode_oneof_fun(ast, oneofs)
    ast = make_encode_fun_field(ast, fields, keep_unknown_fields)

    case ast do
      [] ->
        quote do
          @spec encode(struct) :: {:ok, iodata}
          def encode(msg) do
            {:ok, encode!(msg)}
          end

          @spec encode!(struct) :: iodata
          def encode!(_msg), do: []
        end

      _ ->
        quote do
          @spec encode(struct) :: {:ok, iodata} | {:error, any}
          def encode(msg) do
            try do
              {:ok, encode!(msg)}
            rescue
              e -> {:error, e}
            end
          end

          @spec encode!(struct) :: iodata | no_return
          def encode!(msg), do: unquote(ast)
        end
    end
  end

  defp make_encode_fun_field(ast, [], _keep_unknown_fields = true) do
    # credo:disable-for-next-line Credo.Check.Readability.SinglePipe
    quote do: unquote(ast) |> encode_unknown_fields(msg)
  end

  defp make_encode_fun_field(ast, [], _keep_unknown_fields = false) do
    # credo:disable-for-next-line Credo.Check.Readability.SinglePipe
    quote do: unquote(ast)
  end

  defp make_encode_fun_field(ast, [field | fields], keep_unknown_fields) do
    {_, _, name, _, _} = field
    fun_name = String.to_atom("encode_#{name}")

    # credo:disable-for-next-line Credo.Check.Readability.SinglePipe
    ast = quote do: unquote(ast) |> unquote(fun_name)(msg)

    make_encode_fun_field(ast, fields, keep_unknown_fields)
  end

  defp make_encode_oneof_fun(ast, []), do: ast

  defp make_encode_oneof_fun(ast, [oneof | oneofs]) do
    {parent_name, _} = oneof
    fun_name = String.to_atom("encode_#{parent_name}")

    # credo:disable-for-next-line Credo.Check.Readability.SinglePipe
    ast = quote do: unquote(ast) |> unquote(fun_name)(msg)

    make_encode_oneof_fun(ast, oneofs)
  end

  defp parent_name(_, [{_, :proto3_optional, _, {_, name}, _}]), do: name
  defp parent_name(name, _), do: name

  defp parent_data_key(_, [{_, :proto3_optional, child_name, _, _}]), do: child_name
  defp parent_data_key(parent_name, _), do: parent_name

  defp make_encode_oneof_funs(oneofs) do
    for {parent_name, children} <- oneofs do
      nil_case =
        quote do
          nil -> acc
        end

      children_case_ast =
        nil_case ++
          (children
           |> Enum.map(fn {_, _, child_name, _, _} ->
             encode_child_fun_name = String.to_atom("encode_#{child_name}")

             quote do
               {unquote(child_name), _field_value} -> unquote(encode_child_fun_name)(acc, msg)
             end
           end)
           |> List.flatten())

      parent_name = parent_name(parent_name, children)
      encode_parent_fun_name = String.to_atom("encode_#{parent_name}")
      parent_data_key = parent_data_key(parent_name, children)

      quote do
        defp unquote(encode_parent_fun_name)(acc, msg) do
          case msg.unquote(parent_data_key) do
            unquote(children_case_ast)
          end
        end
      end
    end
  end

  defp make_encode_field_funs(fields, required_fields, syntax) do
    for {_, _, name, _, _} = field <- fields do
      required = name in required_fields
      fun_name = String.to_atom("encode_#{name}")
      fun_ast = make_encode_field_body(field, required, syntax)

      quote do
        defp unquote(fun_name)(acc, msg), do: unquote(fun_ast)
      end
    end
  end

  defp make_encode_field_body({tag, _, name, {:default, default}, type}, required, syntax) do
    key = Protox.Encode.make_key_bytes(tag, type)
    var = quote do: field_value
    encode_value_ast = get_encode_value_body(type, var)

    case syntax do
      :proto2 ->
        if required do
          quote do
            case msg.unquote(name) do
              nil -> raise Protox.RequiredFieldsError.new([unquote(name)])
              unquote(var) -> [acc, unquote(key), unquote(encode_value_ast)]
            end
          end
        else
          quote do
            unquote(var) = msg.unquote(name)

            case unquote(var) do
              nil -> acc
              _ -> [acc, unquote(key), unquote(encode_value_ast)]
            end
          end
        end

      :proto3 ->
        quote do
          unquote(var) = msg.unquote(name)

          # Use == rather than pattern match for float comparison
          if unquote(var) == unquote(default) do
            acc
          else
            [acc, unquote(key), unquote(encode_value_ast)]
          end
        end
    end
  end

  # Generate the AST to encode child `_child_name` of oneof `parent_field`
  defp make_encode_field_body(
         {tag, label, child_name, {:oneof, parent_field}, type},
         _required,
         _syntax
       ) do
    key = Protox.Encode.make_key_bytes(tag, type)
    var = quote do: field_value
    encode_value_ast = get_encode_value_body(type, var)

    case label do
      :proto3_optional ->
        quote do
          case msg.unquote(child_name) do
            {_, unquote(var)} ->
              [acc, unquote(key), unquote(encode_value_ast)]

            unquote(var) when not is_nil(unquote(var)) ->
              [acc, unquote(key), unquote(encode_value_ast)]

            _ ->
              [acc]
          end
        end

      _ ->
        # The dispatch on the correct child is performed by the parent encoding function,
        # this is why we don't check if the child is set.
        quote do
          {_, unquote(var)} = msg.unquote(parent_field)
          [acc, unquote(key), unquote(encode_value_ast)]
        end
    end
  end

  defp make_encode_field_body({tag, _label, name, :packed, type}, _required, _syntax) do
    key = Protox.Encode.make_key_bytes(tag, :packed)
    encode_packed_ast = make_encode_packed_body(type)

    quote do
      case msg.unquote(name) do
        [] -> acc
        values -> [acc, unquote(key), unquote(encode_packed_ast)]
      end
    end
  end

  defp make_encode_field_body({tag, _label, name, :unpacked, type}, _required, _syntax) do
    encode_repeated_ast = make_encode_repeated_body(tag, type)

    quote do
      case msg.unquote(name) do
        [] -> acc
        values -> [acc, unquote(encode_repeated_ast)]
      end
    end
  end

  defp make_encode_field_body({tag, _label, name, :map, type}, _required, _syntax) do
    # Each key/value entry of a map has the same layout as a message.
    # https://developers.google.com/protocol-buffers/docs/proto3#backwards-compatibility

    key = Protox.Encode.make_key_bytes(tag, :map_entry)

    {map_key_type, map_value_type} = type

    k_var = quote do: k
    v_var = quote do: v
    encode_map_key_ast = get_encode_value_body(map_key_type, k_var)
    encode_map_value_ast = get_encode_value_body(map_value_type, v_var)

    map_key_key_bytes = Protox.Encode.make_key_bytes(1, map_key_type)
    map_value_key_bytes = Protox.Encode.make_key_bytes(2, map_value_type)
    map_keys_len = byte_size(map_value_key_bytes) + byte_size(map_key_key_bytes)

    quote do
      map = Map.fetch!(msg, unquote(name))

      Enum.reduce(map, acc, fn {unquote(k_var), unquote(v_var)}, acc ->
        map_key_value_bytes = :binary.list_to_bin([unquote(encode_map_key_ast)])
        map_key_value_len = byte_size(map_key_value_bytes)

        map_value_value_bytes = :binary.list_to_bin([unquote(encode_map_value_ast)])
        map_value_value_len = byte_size(map_value_value_bytes)

        len =
          Protox.Varint.encode(unquote(map_keys_len) + map_key_value_len + map_value_value_len)

        [
          acc,
          unquote(key),
          len,
          unquote(map_key_key_bytes),
          map_key_value_bytes,
          unquote(map_value_key_bytes),
          map_value_value_bytes
        ]
      end)
    end
  end

  defp make_encode_unknown_fields_fun(_keep_unknown_fields = true) do
    quote do
      defp encode_unknown_fields(acc, msg) do
        Enum.reduce(msg.__struct__.unknown_fields(msg), acc, fn {tag, wire_type, bytes}, acc ->
          case wire_type do
            0 ->
              [acc, Protox.Encode.make_key_bytes(tag, :int32), bytes]

            1 ->
              [acc, Protox.Encode.make_key_bytes(tag, :double), bytes]

            2 ->
              len_bytes = bytes |> byte_size() |> Protox.Varint.encode()
              [acc, Protox.Encode.make_key_bytes(tag, :packed), len_bytes, bytes]

            5 ->
              [acc, Protox.Encode.make_key_bytes(tag, :float), bytes]
          end
        end)
      end
    end
  end

  defp make_encode_unknown_fields_fun(_keep_unknown_fields = false) do
    []
  end

  defp make_encode_packed_body(type) do
    var = quote do: value
    encode_value_ast = get_encode_value_body(type, var)

    quote do
      {bytes, len} =
        Enum.reduce(values, {[], 0}, fn unquote(var), {acc, len} ->
          value_bytes = :binary.list_to_bin([unquote(encode_value_ast)])
          {[acc, value_bytes], len + byte_size(value_bytes)}
        end)

      [Protox.Varint.encode(len), bytes]
    end
  end

  defp make_encode_repeated_body(tag, type) do
    key = Protox.Encode.make_key_bytes(tag, type)
    var = quote do: value
    encode_value_ast = get_encode_value_body(type, var)

    quote do
      Enum.reduce(values, [], fn unquote(var), acc ->
        [acc, unquote(key), unquote(encode_value_ast)]
      end)
    end
  end

  defp get_encode_value_body({:message, _}, var) do
    quote do
      Protox.Encode.encode_message(unquote(var))
    end
  end

  defp get_encode_value_body({:enum, enum}, var) do
    quote do
      unquote(var) |> unquote(enum).encode() |> Protox.Encode.encode_enum()
    end
  end

  defp get_encode_value_body(:bool, var) do
    quote(do: Protox.Encode.encode_bool(unquote(var)))
  end

  defp get_encode_value_body(:bytes, var) do
    quote(do: Protox.Encode.encode_bytes(unquote(var)))
  end

  defp get_encode_value_body(:string, var) do
    quote(do: Protox.Encode.encode_string(unquote(var)))
  end

  defp get_encode_value_body(:int32, var) do
    quote(do: Protox.Encode.encode_int32(unquote(var)))
  end

  defp get_encode_value_body(:int64, var) do
    quote(do: Protox.Encode.encode_int64(unquote(var)))
  end

  defp get_encode_value_body(:uint32, var) do
    quote(do: Protox.Encode.encode_uint32(unquote(var)))
  end

  defp get_encode_value_body(:uint64, var) do
    quote(do: Protox.Encode.encode_uint64(unquote(var)))
  end

  defp get_encode_value_body(:sint32, var) do
    quote(do: Protox.Encode.encode_sint32(unquote(var)))
  end

  defp get_encode_value_body(:sint64, var) do
    quote(do: Protox.Encode.encode_sint64(unquote(var)))
  end

  defp get_encode_value_body(:fixed32, var) do
    quote(do: Protox.Encode.encode_fixed32(unquote(var)))
  end

  defp get_encode_value_body(:fixed64, var) do
    quote(do: Protox.Encode.encode_fixed64(unquote(var)))
  end

  defp get_encode_value_body(:sfixed32, var) do
    quote(do: Protox.Encode.encode_sfixed32(unquote(var)))
  end

  defp get_encode_value_body(:sfixed64, var) do
    quote(do: Protox.Encode.encode_sfixed64(unquote(var)))
  end

  defp get_encode_value_body(:float, var) do
    quote(do: Protox.Encode.encode_float(unquote(var)))
  end

  defp get_encode_value_body(:double, var) do
    quote(do: Protox.Encode.encode_double(unquote(var)))
  end
end
