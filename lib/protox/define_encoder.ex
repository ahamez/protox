defmodule Protox.DefineEncoder do
  @moduledoc false
  # Internal. Generates the encoder of a message.

  def define(fields, required_fields, syntax) do
    make_encode(fields, required_fields, syntax)
  end

  # -- Private

  defp make_encode([], _, _) do
    quote do
      @spec encode(struct) :: iolist
      def encode(msg), do: []
    end
  end

  defp make_encode(fields, required_fields, syntax) do
    # It is recommended to encode fields sequentially by field number.
    # See https://developers.google.com/protocol-buffers/docs/encoding#order.
    sorted_fields = Enum.sort(fields, &(elem(&1, 0) < elem(&2, 0)))
    encode_fun = make_encode_fun(sorted_fields)
    encode_field_funs = make_encode_field_funs(fields, required_fields, syntax)
    encode_unknown_fields_fun = make_encode_unknown_fields_fun()

    quote do
      @spec encode(struct) :: iolist
      def encode(msg), do: unquote(encode_fun)

      unquote(encode_field_funs)
      unquote(encode_unknown_fields_fun)
    end
  end

  defp make_encode_fun(fields) do
    ast = quote do: []
    make_encode_fun(ast, fields)
  end

  defp make_encode_fun(ast, []) do
    quote do
      unquote(ast) |> encode_unknown_fields(msg)
    end
  end

  defp make_encode_fun(ast, [field | fields]) do
    {_, _, name, _, _} = field
    fun_name = String.to_atom("encode_#{name}")

    ast =
      quote do
        unquote(ast) |> unquote(fun_name)(msg)
      end

    make_encode_fun(ast, fields)
  end

  defp make_encode_field_funs(fields, required_fields, syntax) do
    for {tag, _, name, kind, type} <- fields do
      required = name in required_fields
      fun_name = String.to_atom("encode_#{name}")
      fun_ast = make_encode_field_fun(kind, tag, name, type, required, syntax)

      quote do
        defp unquote(fun_name)(acc, msg), do: unquote(fun_ast)
      end
    end
  end

  defp make_encode_field_fun({:default, default}, tag, name, type, required, syntax) do
    key = Protox.Encode.make_key_bytes(tag, type)
    var = quote do: field_value
    encode_value_ast = get_encode_value_ast(type, var)

    case syntax do
      :proto2 ->
        if required do
          quote do
            unquote(var) = msg.unquote(name)
            [acc, unquote(key), unquote(encode_value_ast)]
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
          default = unquote(default)

          # Use == rather than pattern match for float comparison
          if unquote(var) == default do
            acc
          else
            [acc, unquote(key), unquote(encode_value_ast)]
          end
        end
    end
  end

  defp make_encode_field_fun({:oneof, parent_field}, tag, name, type, _required, _syntax) do
    key = Protox.Encode.make_key_bytes(tag, type)
    var = quote do: field_value
    encode_value_ast = get_encode_value_ast(type, var)

    quote do
      name = unquote(name)

      case msg.unquote(parent_field) do
        # The parent oneof field is set to the current field.
        {^name, field_value} ->
          [acc, unquote(key), unquote(encode_value_ast)]

        _ ->
          acc
      end
    end
  end

  defp make_encode_field_fun(:packed, tag, name, type, _required, _syntax) do
    key = Protox.Encode.make_key_bytes(tag, :packed)
    encode_packed_ast = make_encode_packed_ast(type)

    quote do
      case msg.unquote(name) do
        [] -> acc
        values -> [acc, unquote(key), unquote(encode_packed_ast)]
      end
    end
  end

  defp make_encode_field_fun(:unpacked, tag, name, type, _required, _syntax) do
    encode_repeated_ast = make_encode_repeated_ast(tag, type)

    quote do
      case msg.unquote(name) do
        [] -> acc
        values -> [acc, unquote(encode_repeated_ast)]
      end
    end
  end

  defp make_encode_field_fun(:map, tag, name, type, _required, _syntax) do
    # Each key/value entry of a map has the same layout as a message.
    # https://developers.google.com/protocol-buffers/docs/proto3#backwards-compatibility

    key = Protox.Encode.make_key_bytes(tag, :map_entry)

    {map_key_type, map_value_type} = type

    k_var = quote do: k
    v_var = quote do: v
    encode_map_key_ast = get_encode_value_ast(map_key_type, k_var)
    encode_map_value_ast = get_encode_value_ast(map_value_type, v_var)

    map_key_key_bytes = Protox.Encode.make_key_bytes(1, map_key_type)
    map_value_key_bytes = Protox.Encode.make_key_bytes(2, map_value_type)
    map_keys_len = byte_size(map_value_key_bytes) + byte_size(map_key_key_bytes)

    quote do
      map = Map.fetch!(msg, unquote(name))

      if map_size(map) == 0 do
        acc
      else
        Enum.reduce(map, acc, fn {unquote(k_var), unquote(v_var)}, acc ->
          map_key_value_bytes = [unquote(encode_map_key_ast)] |> :binary.list_to_bin()
          map_key_value_len = byte_size(map_key_value_bytes)

          map_value_value_bytes = [unquote(encode_map_value_ast)] |> :binary.list_to_bin()
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
  end

  defp make_encode_unknown_fields_fun() do
    quote do
      defp encode_unknown_fields(acc, msg) do
        Enum.reduce(msg.__struct__.unknown_fields(msg), acc, fn {tag, wire_type, bytes}, acc ->
          case wire_type do
            0 ->
              [acc, make_key_bytes(tag, :int32), bytes]

            1 ->
              [acc, make_key_bytes(tag, :double), bytes]

            2 ->
              len_bytes = bytes |> byte_size() |> Protox.Varint.encode()
              [acc, make_key_bytes(tag, :packed), len_bytes, bytes]

            5 ->
              [acc, make_key_bytes(tag, :float), bytes]
          end
        end)
      end
    end
  end

  defp make_encode_packed_ast(type) do
    var = quote do: value
    encode_value_ast = get_encode_value_ast(type, var)

    quote do
      {bytes, len} =
        Enum.reduce(values, {[], 0}, fn unquote(var), {acc, len} ->
          value_bytes = [unquote(encode_value_ast)] |> :binary.list_to_bin()
          {[acc, value_bytes], len + byte_size(value_bytes)}
        end)

      [Protox.Varint.encode(len), bytes]
    end
  end

  defp make_encode_repeated_ast(tag, type) do
    key = Protox.Encode.make_key_bytes(tag, type)
    var = quote do: value
    encode_value_ast = get_encode_value_ast(type, var)

    quote do
      Enum.reduce(values, [], fn unquote(var), acc ->
        bytes = [acc, unquote(key), unquote(encode_value_ast)]
      end)
    end
  end

  defp get_encode_value_ast({:message, _}, var) do
    quote do
      encode_message(unquote(var))
    end
  end

  defp get_encode_value_ast({:enum, enum}, var) do
    quote do
      unquote(var) |> unquote(enum).encode() |> encode_enum()
    end
  end

  defp get_encode_value_ast(type, var) do
    fun_name = String.to_atom("encode_#{type}")

    quote do
      unquote(fun_name)(unquote(var))
    end
  end
end
