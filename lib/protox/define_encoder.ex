defmodule Protox.DefineEncoder do
  @moduledoc false
  # Internal. Generates the encoder of a message.

  alias Protox.Field

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
    quote(do: [])
    |> make_encode_oneof_fun(oneofs)
    |> make_encode_fun_field(fields, keep_unknown_fields)
    |> make_encode_fun_body()
  end

  defp make_encode_fun_body([] = _ast) do
    quote do
      @spec encode(struct) :: {:ok, iodata}
      def encode(msg) do
        {:ok, encode!(msg)}
      end

      @spec encode!(struct) :: iodata
      def encode!(_msg), do: []
    end
  end

  defp make_encode_fun_body(ast) do
    quote do
      @spec encode(struct) :: {:ok, iodata} | {:error, any}
      def encode(msg) do
        try do
          {:ok, encode!(msg)}
        rescue
          e in [Protox.EncodingError, Protox.RequiredFieldsError] ->
            {:error, e}
        end
      end

      @spec encode!(struct) :: iodata | no_return
      def encode!(msg), do: unquote(ast)
    end
  end

  defp make_encode_fun_field(ast, fields, keep_unknown_fields) do
    ast =
      Enum.reduce(fields, ast, fn %Protox.Field{} = field, ast_acc ->
        fun_name = String.to_atom("encode_#{field.name}")

        quote(do: unquote(ast_acc) |> unquote(fun_name)(msg))
      end)

    case keep_unknown_fields do
      true -> quote(do: unquote(ast) |> encode_unknown_fields(msg))
      false -> ast
    end
  end

  defp make_encode_oneof_fun(ast, oneofs) do
    Enum.reduce(oneofs, ast, fn {parent_name, _children}, ast_acc ->
      fun_name = String.to_atom("encode_#{parent_name}")
      quote(do: unquote(ast_acc) |> unquote(fun_name)(msg))
    end)
  end

  defp parent_name(_, [%Protox.Field{label: :proto3_optional, kind: {_, name}}]), do: name
  defp parent_name(name, _), do: name

  defp parent_data_key(_, [%Protox.Field{label: :proto3_optional, name: child_name}]) do
    child_name
  end

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
           |> Enum.map(fn %Field{} = child_field ->
             encode_child_fun_name = String.to_atom("encode_#{child_field.name}")

             quote do
               {unquote(child_field.name), _field_value} ->
                 unquote(encode_child_fun_name)(acc, msg)
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
    vars = %{
      acc: Macro.var(:acc, __MODULE__),
      msg: Macro.var(:msg, __MODULE__)
    }

    for %Field{name: name} = field <- fields do
      required = name in required_fields
      fun_name = String.to_atom("encode_#{name}")
      fun_ast = make_encode_field_body(field, required, syntax, vars)

      quote do
        defp unquote(fun_name)(unquote(vars.acc), unquote(vars.msg)) do
          try do
            unquote(fun_ast)
          rescue
            ArgumentError ->
              reraise Protox.EncodingError.new(unquote(name), "invalid field value"),
                      __STACKTRACE__
          end
        end
      end
    end
  end

  defp make_encode_field_body(%Field{kind: {:scalar, default}} = field, required, syntax, vars) do
    key = make_key_bytes(field.tag, field.type)
    var = quote do: unquote(vars.msg).unquote(field.name)
    encode_value_ast = get_encode_value_body(field.type, var)

    case syntax do
      :proto2 ->
        if required do
          quote do
            case unquote(vars.msg).unquote(field.name) do
              nil -> raise Protox.RequiredFieldsError.new([unquote(field.name)])
              _ -> [unquote(vars.acc), unquote(key), unquote(encode_value_ast)]
            end
          end
        else
          quote do
            case unquote(var) do
              nil -> unquote(vars.acc)
              _ -> [unquote(vars.acc), unquote(key), unquote(encode_value_ast)]
            end
          end
        end

      :proto3 ->
        quote do
          # Use == rather than pattern match for float comparison
          if unquote(var) == unquote(default) do
            unquote(vars.acc)
          else
            [unquote(vars.acc), unquote(key), unquote(encode_value_ast)]
          end
        end
    end
  end

  # Generate the AST to encode child `field.name` of oneof `parent_field`
  defp make_encode_field_body(
         %Field{kind: {:oneof, parent_field}} = child_field,
         _required,
         _syntax,
         vars
       ) do
    key = make_key_bytes(child_field.tag, child_field.type)
    var = Macro.var(:child_field_value, __MODULE__)
    encode_value_ast = get_encode_value_body(child_field.type, var)

    case child_field.label do
      :proto3_optional ->
        quote do
          case unquote(vars.msg).unquote(child_field.name) do
            {_, unquote(var)} ->
              [unquote(vars.acc), unquote(key), unquote(encode_value_ast)]

            unquote(var) when not is_nil(unquote(var)) ->
              [unquote(vars.acc), unquote(key), unquote(encode_value_ast)]

            _ ->
              [unquote(vars.acc)]
          end
        end

      _ ->
        # The dispatch on the correct child is performed by the parent encoding function,
        # this is why we don't check if the child is set.
        quote do
          {_, unquote(var)} = unquote(vars.msg).unquote(parent_field)
          [unquote(vars.acc), unquote(key), unquote(encode_value_ast)]
        end
    end
  end

  defp make_encode_field_body(%Field{kind: :packed} = field, _required, _syntax, vars) do
    key = make_key_bytes(field.tag, :packed)
    encode_packed_ast = make_encode_packed_body(field.type)

    quote do
      case unquote(vars.msg).unquote(field.name) do
        [] -> unquote(vars.acc)
        values -> [unquote(vars.acc), unquote(key), unquote(encode_packed_ast)]
      end
    end
  end

  defp make_encode_field_body(%Field{kind: :unpacked} = field, _required, _syntax, vars) do
    encode_repeated_ast = make_encode_repeated_body(field.tag, field.type)

    quote do
      case unquote(vars.msg).unquote(field.name) do
        [] -> unquote(vars.acc)
        values -> [unquote(vars.acc), unquote(encode_repeated_ast)]
      end
    end
  end

  defp make_encode_field_body(%Field{kind: :map} = field, _required, _syntax, vars) do
    # Each key/value entry of a map has the same layout as a message.
    # https://developers.google.com/protocol-buffers/docs/proto3#backwards-compatibility

    key = make_key_bytes(field.tag, :map_entry)

    {map_key_type, map_value_type} = field.type

    k_var = Macro.var(:k, __MODULE__)
    v_var = Macro.var(:v, __MODULE__)

    encode_map_key_ast = get_encode_value_body(map_key_type, k_var)
    encode_map_value_ast = get_encode_value_body(map_value_type, v_var)

    map_key_key_bytes = make_key_bytes(1, map_key_type)
    map_value_key_bytes = make_key_bytes(2, map_value_type)
    map_keys_len = byte_size(map_value_key_bytes) + byte_size(map_key_key_bytes)

    quote do
      map = Map.fetch!(unquote(vars.msg), unquote(field.name))

      Enum.reduce(map, unquote(vars.acc), fn {unquote(k_var), unquote(v_var)},
                                             unquote(vars.acc) ->
        map_key_value_bytes = :binary.list_to_bin([unquote(encode_map_key_ast)])
        map_key_value_len = byte_size(map_key_value_bytes)

        map_value_value_bytes = :binary.list_to_bin([unquote(encode_map_value_ast)])
        map_value_value_len = byte_size(map_value_value_bytes)

        len =
          Protox.Varint.encode(unquote(map_keys_len) + map_key_value_len + map_value_value_len)

        [
          unquote(vars.acc),
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

  defp make_encode_unknown_fields_fun(true = _keep_unknown_fields) do
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

  defp make_encode_unknown_fields_fun(false = _keep_unknown_fields) do
    []
  end

  defp make_encode_packed_body(type) do
    value_var = Macro.var(:value, __MODULE__)
    encode_value_ast = get_encode_value_body(type, value_var)

    quote do
      {bytes, len} =
        Enum.reduce(values, {[], 0}, fn unquote(value_var), {acc, len} ->
          value_bytes = :binary.list_to_bin([unquote(encode_value_ast)])
          {[acc, value_bytes], len + byte_size(value_bytes)}
        end)

      [Protox.Varint.encode(len), bytes]
    end
  end

  defp make_encode_repeated_body(tag, type) do
    key = make_key_bytes(tag, type)
    value_var = Macro.var(:value, __MODULE__)
    encode_value_ast = get_encode_value_body(type, value_var)

    quote do
      Enum.reduce(values, [], fn unquote(value_var), acc ->
        [acc, unquote(key), unquote(encode_value_ast)]
      end)
    end
  end

  defp get_encode_value_body({:message, _}, value_var) do
    quote do
      Protox.Encode.encode_message(unquote(value_var))
    end
  end

  defp get_encode_value_body({:enum, enum}, value_var) do
    quote do
      unquote(value_var) |> unquote(enum).encode() |> Protox.Encode.encode_enum()
    end
  end

  defp get_encode_value_body(:bool, value_var) do
    quote(do: Protox.Encode.encode_bool(unquote(value_var)))
  end

  defp get_encode_value_body(:bytes, value_var) do
    quote(do: Protox.Encode.encode_bytes(unquote(value_var)))
  end

  defp get_encode_value_body(:string, value_var) do
    quote(do: Protox.Encode.encode_string(unquote(value_var)))
  end

  defp get_encode_value_body(:int32, value_var) do
    quote(do: Protox.Encode.encode_int32(unquote(value_var)))
  end

  defp get_encode_value_body(:int64, value_var) do
    quote(do: Protox.Encode.encode_int64(unquote(value_var)))
  end

  defp get_encode_value_body(:uint32, value_var) do
    quote(do: Protox.Encode.encode_uint32(unquote(value_var)))
  end

  defp get_encode_value_body(:uint64, value_var) do
    quote(do: Protox.Encode.encode_uint64(unquote(value_var)))
  end

  defp get_encode_value_body(:sint32, value_var) do
    quote(do: Protox.Encode.encode_sint32(unquote(value_var)))
  end

  defp get_encode_value_body(:sint64, value_var) do
    quote(do: Protox.Encode.encode_sint64(unquote(value_var)))
  end

  defp get_encode_value_body(:fixed32, value_var) do
    quote(do: Protox.Encode.encode_fixed32(unquote(value_var)))
  end

  defp get_encode_value_body(:fixed64, value_var) do
    quote(do: Protox.Encode.encode_fixed64(unquote(value_var)))
  end

  defp get_encode_value_body(:sfixed32, value_var) do
    quote(do: Protox.Encode.encode_sfixed32(unquote(value_var)))
  end

  defp get_encode_value_body(:sfixed64, value_var) do
    quote(do: Protox.Encode.encode_sfixed64(unquote(value_var)))
  end

  defp get_encode_value_body(:float, value_var) do
    quote(do: Protox.Encode.encode_float(unquote(value_var)))
  end

  defp get_encode_value_body(:double, value_var) do
    quote(do: Protox.Encode.encode_double(unquote(value_var)))
  end

  # Flatten an iolist into a binary at generation-time.
  defp make_key_bytes(tag, ty) do
    IO.iodata_to_binary(Protox.Encode.make_key_bytes(tag, ty))
  end
end
