defmodule Protox.BuildMessage do

  defmacro __using__(definitions: defs) do
    defs
    |> Enum.map(
       fn {:{}, _, [def_type, {_, _, name}, fs ]} ->
          fields = for {_, _, f} <- fs do
            List.to_tuple(f)
          end
          {def_type, name, fields}
       end)
    |> build()
  end


  def build(defs) do

    for {:message, name, fields} <- defs do
    # for {name, fields} <- defs do

      msg_name       = Module.concat(name)
      struct_fields  = make_struct_fields(fields)
      fields_map     = make_fields_map(fields)
      tags           = make_tags(fields)
      encode_meta    = make_encode(fields)
      encode_members = make_encode_members(fields)

      quote do
        defmodule unquote(msg_name) do
          @moduledoc false

          defstruct unquote(struct_fields)


          unquote(encode_meta)
          unquote(encode_members)
          defp encode_member(x), do: Varint.LEB128.encode(x)


          @spec encode(struct) :: iolist
          def encode_dyn(msg = %unquote(msg_name){}) do
            Protox.EncodeDyn.encode(msg)
          end


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


  defp make_encode_field_fun(:normal, tag, name, type) do
    default          = get_default(type)
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
        [acc, unquote(key), unquote(encode_value_ast)]
      end)
    end
  end


  defp get_default({:enum, members}) do
    {_, res} = Enum.find(members, fn {x, _} -> x == 0 end)
    res
  end
  defp get_default({:message, _}) do
    nil
  end
  defp get_default(type) do
    Protox.Default.default(type)
  end


  defp get_encode_value_ast({:message, _}, var) do
    quote do
      apply(Protox.Encode, :encode_message, [unquote(var)])
    end
  end
  defp get_encode_value_ast({:enum, _}, var) do
    quote do
      encode_member(unquote(var))
    end
  end
  defp get_encode_value_ast(type, var) do
    fun_name = String.to_atom("encode_#{type}")
    quote do
      apply(Protox.Encode, unquote(fun_name), [unquote(var)])
    end
  end


  # TODO. Enums can be values of maps.
  defp make_encode_members(fields) do
    fields
    |> Enum.reduce(
       %{},
       fn
         ({_, _, _, {:enum, members}}, acc) ->
           Map.merge(acc, (for {value, member} <- members, into: %{}, do: {member, value}))
         (_, acc) ->
           acc
       end)
    |> Enum.map(fn {member, value} ->
          quote do
            defp encode_member(unquote(member)) do
              Varint.LEB128.encode(unquote(value))
            end
          end
       end)
  end


  # -- Private


  defp make_struct_fields(fields) do
    for {_tag, name, kind, type} <- fields do
      case kind do
        :map             -> {name, Macro.escape(%{})}
        {:oneof, parent} -> {parent, nil}
        {:repeated, _}   -> {name, []}
        :normal          ->
          case type do
            {:enum, [{_, first} | _]} -> {name, first}
            {:message, _}             -> {name, nil}
            _                         -> {name, Protox.Default.default(type)}
          end
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

        {_, {:enum, members}} ->
          %Protox.Enumeration{
            members: Map.new(members),
            values: (for {rank, atom} <- members, into: %{}, do: {atom, rank})
          }

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