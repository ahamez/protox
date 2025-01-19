defmodule Protox.DefineEncoder do
  @moduledoc false
  # Internal. Generates the encoder of a message.

  alias Protox.{Field, Scalar}

  def define(fields, required_fields, syntax, opts \\ []) do
    {unknown_fields_name, _opts} = Keyword.pop!(opts, :unknown_fields_name)

    %{oneofs: oneofs, proto3_optionals: proto3_optionals, others: fields_without_oneofs} =
      Protox.Defs.split_oneofs(fields)

    top_level_encode_fun =
      make_top_level_encode_fun(oneofs, proto3_optionals ++ fields_without_oneofs)

    encode_oneof_funs = make_encode_oneof_funs(oneofs)
    encode_field_funs = make_encode_field_funs(fields, required_fields, syntax)

    encode_unknown_fields_fun = make_encode_unknown_fields_fun(unknown_fields_name)

    quote do
      unquote(top_level_encode_fun)
      unquote(encode_oneof_funs)
      unquote(encode_field_funs)
      unquote(encode_unknown_fields_fun)
    end
  end

  defp make_top_level_encode_fun(oneofs, fields) do
    ast =
      quote do
        [
          unquote_splicing(make_encode_oneof_fun(oneofs)),
          unquote_splicing(make_encode_fun_field(fields))
        ]
      end

    make_encode_fun_body(ast)
  end

  defp make_encode_fun_body([] = _ast) do
    quote do
      @spec encode(struct()) :: {:ok, iodata()}
      def encode(msg) do
        {:ok, encode!(msg)}
      end

      @spec encode!(struct()) :: iodata()
      def encode!(_msg), do: []
    end
  end

  defp make_encode_fun_body(ast) do
    quote do
      @spec encode(struct()) :: {:ok, iodata()} | {:error, any()}
      def encode(msg) do
        try do
          {:ok, encode!(msg)}
        rescue
          e in [Protox.EncodingError, Protox.RequiredFieldsError] ->
            {:error, e}
        end
      end

      @spec encode!(struct()) :: iodata() | no_return()
      def encode!(msg), do: unquote(ast)
    end
  end

  defp make_encode_fun_field(fields) do
    ast =
      Enum.map(fields, fn %Protox.Field{} = field ->
        fun_name = String.to_atom("encode_#{field.name}")

        quote(do: unquote(fun_name)(msg))
      end)

    quote do
      [unquote_splicing(ast), encode_unknown_fields(msg)]
    end
  end

  defp make_encode_oneof_fun(oneofs) do
    Enum.map(oneofs, fn {parent_name, _children} ->
      fun_name = String.to_atom("encode_#{parent_name}")
      quote(do: unquote(fun_name)(msg))
    end)
  end

  defp make_encode_oneof_funs(oneofs) do
    for {parent_name, children} <- oneofs do
      nil_case =
        quote do
          nil -> []
        end

      children_case_ast =
        nil_case ++
          (children
           |> Enum.map(fn %Field{} = child_field ->
             encode_child_fun_name = String.to_atom("encode_#{child_field.name}")

             quote do
               {unquote(child_field.name), _field_value} ->
                 unquote(encode_child_fun_name)(msg)
             end
           end)
           |> List.flatten())

      encode_parent_fun_name = String.to_atom("encode_#{parent_name}")

      quote do
        defp unquote(encode_parent_fun_name)(msg) do
          case msg.unquote(parent_name) do
            unquote(children_case_ast)
          end
        end
      end
    end
  end

  defp make_encode_field_funs(fields, required_fields, syntax) do
    vars = %{
      msg: Macro.var(:msg, __MODULE__)
    }

    for %Field{name: name} = field <- fields do
      required = name in required_fields
      fun_name = String.to_atom("encode_#{name}")
      fun_ast = make_encode_field_body(field, required, syntax, vars)

      quote do
        defp unquote(fun_name)(unquote(vars.msg)) do
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

  defp make_encode_field_body(%Field{kind: %Scalar{}} = field, required, syntax, vars) do
    key = make_key_bytes(field.tag, field.type)
    var = quote do: unquote(vars.msg).unquote(field.name)
    encode_value_ast = get_encode_value_body(field.type, var)

    case syntax do
      :proto2 ->
        if required do
          quote do
            case unquote(vars.msg).unquote(field.name) do
              nil -> raise Protox.RequiredFieldsError.new([unquote(field.name)])
              _ -> [unquote(key), unquote(encode_value_ast)]
            end
          end
        else
          quote do
            case unquote(var) do
              nil -> []
              _ -> [unquote(key), unquote(encode_value_ast)]
            end
          end
        end

      :proto3 ->
        quote do
          # Use == rather than pattern match for float comparison
          if unquote(var) == unquote(field.kind.default_value) do
            []
          else
            [unquote(key), unquote(encode_value_ast)]
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
            nil -> []
            unquote(var) -> [unquote(key), unquote(encode_value_ast)]
          end
        end

      _ ->
        # The dispatch on the correct child is performed by the parent encoding function,
        # this is why we don't check if the child is set.
        quote do
          {_, unquote(var)} = unquote(vars.msg).unquote(parent_field)
          [unquote(key), unquote(encode_value_ast)]
        end
    end
  end

  defp make_encode_field_body(%Field{kind: :packed} = field, _required, _syntax, vars) do
    key = make_key_bytes(field.tag, :packed)
    encode_packed_ast = make_encode_packed_body(field.type)

    quote do
      case unquote(vars.msg).unquote(field.name) do
        [] ->
          []

        values ->
          {bytes, len} = unquote(encode_packed_ast)
          [unquote(key), Protox.Varint.encode(len), bytes]
      end
    end
  end

  defp make_encode_field_body(%Field{kind: :unpacked} = field, _required, _syntax, vars) do
    encode_repeated_ast = make_encode_repeated_body(field.tag, field.type)

    quote do
      case unquote(vars.msg).unquote(field.name) do
        [] -> []
        values -> unquote(encode_repeated_ast)
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

      Enum.map(map, fn {unquote(k_var), unquote(v_var)} ->
        map_key_value_bytes = :binary.list_to_bin([unquote(encode_map_key_ast)])
        map_key_value_len = byte_size(map_key_value_bytes)

        map_value_value_bytes = :binary.list_to_bin([unquote(encode_map_value_ast)])
        map_value_value_len = byte_size(map_value_value_bytes)

        len =
          Protox.Varint.encode(unquote(map_keys_len) + map_key_value_len + map_value_value_len)

        [
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

  defp make_encode_unknown_fields_fun(unknown_fields_name) do
    quote do
      defp encode_unknown_fields(msg) do
        Enum.map(msg.unquote(unknown_fields_name), fn {tag, wire_type, bytes} ->
          case wire_type do
            0 ->
              [Protox.Encode.make_key_bytes(tag, :int32), bytes]

            1 ->
              [Protox.Encode.make_key_bytes(tag, :double), bytes]

            2 ->
              len_bytes = bytes |> byte_size() |> Protox.Varint.encode()
              [Protox.Encode.make_key_bytes(tag, :packed), len_bytes, bytes]

            5 ->
              [Protox.Encode.make_key_bytes(tag, :float), bytes]
          end
        end)
      end
    end
  end

  defp make_encode_packed_body(type) do
    value_var = Macro.var(:value, __MODULE__)
    encode_value_ast = get_encode_value_body(type, value_var)

    quote do
      Enum.reduce(values, {[], 0}, fn unquote(value_var), {acc, len} ->
        value_bytes = :binary.list_to_bin([unquote(encode_value_ast)])
        {[acc, value_bytes], len + byte_size(value_bytes)}
      end)
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
