defmodule Protox.DefineEncoder do

  @moduledoc false
  # Internal. Generates the encoder of a message.


  def define(fields) do
    make_encode(fields)
  end


  # -- Private


  defp make_encode([]) do
    quote do
      @spec encode(struct) :: iolist
      def encode(msg), do: []
    end
  end
  defp make_encode(fields) do
    # It is recommended to encode fields sequentially by field number.
    # See https://developers.google.com/protocol-buffers/docs/encoding#order.
    sorted_fields = Enum.sort(fields,
      fn {lhs, _, _, _, _}, {rhs, _, _, _, _} -> lhs < rhs
    end)
    encode_fun_body = make_encode_fun(sorted_fields)
    encode_field_funs = make_encode_field_funs(fields)

    quote do
      @spec encode(struct) :: iolist
      def encode(msg), do: unquote(encode_fun_body)

      unquote(encode_field_funs)
    end
  end


  defp make_encode_fun([field | fields]) do
    {_, _, name, _, _} = field
    fun_name = String.to_atom("encode_#{name}")

    ast = quote do
      [] |> unquote(fun_name)(msg)
    end
    make_encode_fun(ast, fields)
  end


  defp make_encode_fun(ast, []) do
    ast
  end
  defp make_encode_fun(ast, [field | fields]) do
    {_, _, name, _, _} = field
    fun_name = String.to_atom("encode_#{name}")

    ast = quote do
      unquote(ast) |> unquote(fun_name)(msg)
    end
    make_encode_fun(ast, fields)
  end


  defp make_encode_field_funs(fields) do
    for {tag, _, name, kind, type} <- fields do
      fun_name = String.to_atom("encode_#{name}")
      fun_ast  = make_encode_field_fun(kind, tag, name, type)

      quote do
        defp unquote(fun_name)(acc, msg), do: unquote(fun_ast)
      end

    end
  end


  defp make_encode_field_fun({:normal, default}, tag, name, type) do
    key              = Protox.Encode.make_key_bytes(tag, type)
    var              = quote do: field_value
    encode_value_ast = get_encode_value_ast(type, var)

    quote do
      unquote(var) = Map.fetch!(msg, unquote(name))
      if unquote(var) == unquote(default) do
        acc
      else
        [
          acc,
          unquote(key),
          unquote(encode_value_ast),
        ]
      end
    end
  end
  defp make_encode_field_fun({:oneof, parent_field}, tag, name, type) do
    key              = Protox.Encode.make_key_bytes(tag, type)
    var              = quote do: field_value
    encode_value_ast = get_encode_value_ast(type, var)

    quote do
      name = unquote(name)

      case Map.fetch!(msg, unquote(parent_field)) do
        nil ->
          acc

        # The parent oneof field is set to the current field.
        {^name, field_value} ->
          [acc, unquote(key), unquote(encode_value_ast)]

        _ ->
         acc
      end
    end
  end
  defp make_encode_field_fun({:repeated, :packed}, tag, name, type) do
    use Bitwise
    key = Varint.LEB128.encode(tag <<< 3 ||| 2) # TODO. Should be in Encode.

    encode_packed_ast = make_encode_packed_ast(type)

    quote do
      case Map.fetch!(msg, unquote(name)) do
        []     -> acc
        values -> [acc, unquote(key), unquote(encode_packed_ast)]
      end
    end
  end
  defp make_encode_field_fun({:repeated, :unpacked}, tag, name, type) do
    encode_repeated_ast = make_encode_repeated_ast(tag, type)

    quote do
      case Map.fetch!(msg, unquote(name)) do
        []     -> acc
        values -> [acc, unquote(encode_repeated_ast)]
      end
    end
  end
  defp make_encode_field_fun(:map, tag, name, type) do
    # Each key/value entry of a map has the same layout as a message.
    # https://developers.google.com/protocol-buffers/docs/proto3#backwards-compatibility

    use Bitwise
    key = Varint.LEB128.encode(tag <<< 3 ||| 2) # TODO. Should be in Encode.

    {map_key_type, map_value_type} = type

    k_var                = quote do: k
    v_var                = quote do: v
    encode_map_key_ast   = get_encode_value_ast(map_key_type, k_var)
    encode_map_value_ast = get_encode_value_ast(map_value_type, v_var)

    map_key_key_bytes = Protox.Encode.make_key_bytes(1, map_key_type)
    map_key_key_len   = byte_size(map_key_key_bytes)

    map_value_key_bytes = Protox.Encode.make_key_bytes(2, map_value_type)
    map_value_key_len   = byte_size(map_value_key_bytes)

    quote do
      map = Map.fetch!(msg, unquote(name))
      if map_size(map) == 0 do
        acc
      else
        Enum.reduce(map, acc,
          fn ({unquote(k_var), unquote(v_var)}, acc) ->

            map_key_value_bytes = unquote(encode_map_key_ast)
            map_key_value_len   = byte_size(map_key_value_bytes)

            map_value_value_bytes = unquote(encode_map_value_ast)
            map_value_value_len   = byte_size(map_value_value_bytes)

            len = Varint.LEB128.encode(
              unquote(map_key_key_len) +
              map_key_value_len +
              unquote(map_value_key_len) +
              map_value_value_len
            )

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


  defp make_encode_packed_ast(type) do
    var = quote do: value
    encode_value_ast = get_encode_value_ast(type, var)

    quote do
      {bytes, len} = Enum.reduce(
        values,
        {[], 0},
        fn (unquote(var), {acc, len}) ->
          value_bytes = unquote(encode_value_ast)
          {[acc, value_bytes], len + byte_size(value_bytes)}
        end)

      [Varint.LEB128.encode(len), bytes]
    end
  end


  defp make_encode_repeated_ast(tag, type) do
    key = Protox.Encode.make_key_bytes(tag, type)
    var = quote do: value
    encode_value_ast = get_encode_value_ast(type, var)

    quote do
      Enum.reduce(
      values,
      [],
      fn (unquote(var), acc) ->
        bytes =
        [acc, unquote(key), unquote(encode_value_ast)]
      end)
    end
  end


  defp get_encode_value_ast({:message, _}, var) do
    quote do
      encode_message(unquote(var))
    end
  end
  defp get_encode_value_ast({:enum, {_, _, enum}}, var) do
    mod = Module.concat(enum)
    quote do
      unquote(var) |> unquote(mod).encode() |> encode_enum()
    end
  end
  defp get_encode_value_ast(type, var) do
    fun_name = String.to_atom("encode_#{type}")
    quote do
      unquote(fun_name)(unquote(var))
    end
  end

end
