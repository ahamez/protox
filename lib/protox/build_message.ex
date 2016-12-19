defmodule Protox.BuildMessage do

  defmacro __using__(enums: enums, messages: messages) do

    build(
      Enum.map(enums,
        fn {{_, _, name}, members} ->
          {name, members}
        end),
      Enum.map(messages,
       fn {{_, _, name}, fs} ->
          fields = for {_, _, f} <- fs, do: List.to_tuple(f)
          {name, fields}
       end)
    )
  end


  def build(enums, messages) do

    for {name, members} <- enums do

      enum_name      = Module.concat(name)
      default        = make_enum_default(members)
      encode_members = make_encode_members(members)
      decode_members = make_decode_members(members)

      quote do
        defmodule unquote(enum_name) do
          @moduledoc false

          unquote(default)

          unquote(encode_members)
          def encode(x), do: x

          unquote(decode_members)
          def decode(x), do: x

          def members(), do: unquote(members)
        end
      end

    end

    ++ # concat enumerations and messages definitions

    for {name, fields} <- messages do

      msg_name       = Module.concat(name)
      struct_fields  = make_struct_fields(fields)
      fields_map     = make_fields_map(fields)
      tags           = make_tags(fields)
      encode_meta    = make_encode(fields)

      quote do
        defmodule unquote(msg_name) do
          @moduledoc false

          import Protox.Encode


          defstruct unquote(struct_fields)


          unquote(encode_meta)


          @spec encode_binary(struct) :: binary
          def encode_binary(msg = %unquote(msg_name){}) do
            Protox.Encode.encode_binary(msg)
          end


          @spec decode(binary) :: struct
          def decode(bytes) do
            Protox.Decode.decode(bytes, unquote(msg_name))
          end


          @spec defs() :: struct
          def defs() do
            %Protox.MessageDefinitions{
              fields: unquote(fields_map),
              tags: unquote(tags)
            }
          end


        end # module
      end
    end # for

  end


  defp make_encode(fields) do

    encode_fun_body    = make_encode_fun(fields)
    encode_field_funs  = make_encode_field_funs(fields)

    quote do

      @spec encode(struct) :: iolist
      def encode(msg), do: unquote(encode_fun_body)

      unquote(encode_field_funs)
    end

  end


  defp make_encode_fun([field | fields]) do
    {_, name, _, _} = field
    fun_name = String.to_atom("encode_#{name}")

    quote do
      [] |> unquote(fun_name)(msg)
    end
    |> make_encode_fun(fields)
  end


  defp make_encode_fun(ast, []) do
    ast
  end
  defp make_encode_fun(ast, [field | fields]) do
    {_, name, _, _} = field
    fun_name = String.to_atom("encode_#{name}")

    quote do
      unquote(ast) |> unquote(fun_name)(msg)
    end
    |> make_encode_fun(fields)
  end


  defp make_encode_field_funs(fields) do
    for {tag, name, kind, type} <- fields do
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


  defp make_enum_default(members) do
    {_, default} = Enum.find(members, fn {x, _} -> x == 0 end)
    quote do
      def default(), do: unquote(default)
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
      unquote(mod).encode(unquote(var)) |> encode_enum()
    end
  end
  defp get_encode_value_ast(type, var) do
    fun_name = String.to_atom("encode_#{type}")
    quote do
      unquote(fun_name)(unquote(var))
    end
  end


  defp make_encode_members(members) do
    for {value, member} <- members do
      quote do
        def encode(unquote(member)), do: unquote(value)
      end
    end
  end


  defp make_decode_members(members) do
    for {value, member} <- members do
      quote do
        def decode(unquote(value)), do: unquote(member)
      end
    end
  end


  # -- Private


  defp make_struct_fields(fields) do
    for {_, name, kind, _} <- fields do
      case kind do
        :map               -> {name, Macro.escape(%{})}
        {:oneof, parent}   -> {parent, nil}
        {:repeated, _}     -> {name, []}
        {:normal, default} -> {name, default}
      end
    end
  end


  defp make_fields_map(fields) do
    for {tag, name, kind, type} <- fields, into: %{} do
      ty = case {kind, type} do
        {:map, {key_type, {:message, msg}}} ->
          {
            key_type,
            %Protox.Message{name: msg |> elem(2) |> Module.concat()}
          }


        {:map, {key_type, {:enum, {_, _, enum}}}} ->
          {
            key_type,
            {:enum, Module.concat(enum)}
          }

        {_, {:enum, {_, _, enum}}} ->
          {:enum, Module.concat(enum)}

        {_, {:message, msg}} ->
          %Protox.Message{name: msg |> elem(2) |> Module.concat()}

        {_, ty} ->
          ty
      end

      {tag, %Protox.Field{name: name, kind: kind, type: ty}}
    end
    |> Macro.escape()
  end


  defp make_tags(fields) do
    Enum.sort(for {tag, _, _, _} <- fields, do: tag)
  end

end
