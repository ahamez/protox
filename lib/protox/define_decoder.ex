defmodule Protox.DefineDecoder do
  @moduledoc false
  # Internal. Generates the decoder of a message.

  use Protox.{
    Float,
    WireTypes
  }

  def define(msg_name, fields, required_fields, syntax) do
    decode_return = make_decode_return(required_fields)
    parse_key_value = make_parse_key_value(syntax, fields)
    parse_map_entries = make_parse_map_entries(fields)

    quote do
      @spec decode(binary) :: {:ok, struct} | {:error, any}
      def decode(bytes) do
        try do
          {:ok, decode!(bytes)}
        rescue
          Protox.IllegalTagError -> {:error, :illegal_tag}
          e in Protox.RequiredFieldsError -> {:error, {:missing_fields, e.missing_fields}}
          e in Protox.DecodingError -> {:error, {e.reason, e.binary}}
          e -> {:error, e}
        end
      end

      @spec decode!(binary) :: struct | no_return
      def decode!(bytes) do
        {msg, set_fields} =
          parse_key_value([], bytes, unquote(msg_name).defs(), struct(unquote(msg_name)))

        unquote(decode_return)
      end

      @spec parse_key_value([atom], binary, map, struct) :: {struct, [atom]}
      defp parse_key_value(set_fields, <<>>, _, msg) do
        {msg, set_fields}
      end

      defp parse_key_value(set_fields, bytes, defs, msg) do
        unquote(parse_key_value)
      end

      unquote(parse_map_entries)
    end
  end

  defp make_decode_return([]), do: quote(do: msg)

  defp make_decode_return(required_fields) do
    quote do
      case unquote(required_fields) -- set_fields do
        [] -> msg
        missing_fields -> raise Protox.RequiredFieldsError.new(missing_fields)
      end
    end
  end

  defp make_parse_key_value(syntax, fields) do
    msg_var = quote do: msg
    field_var = quote do: field
    value_var = quote do: value

    tag_0_case =
      quote do
        {0, _, _} -> raise %Protox.IllegalTagError{}
      end

    unknown_tag_case =
      (
        # No need to maintain a list of set fields for proto3
        case_return =
          case syntax do
            :proto2 -> quote do: {set_fields, unquote(field_var), new_rest}
            :proto3 -> quote do: {[], unquote(field_var), new_rest}
          end

        quote do
          {tag, wire_type, rest} ->
            {unquote(value_var), new_rest} = Protox.Decode.parse_unknown(tag, wire_type, rest)

            unquote(field_var) =
              {unquote(msg_var).__struct__.unknown_fields_name,
               [unquote(value_var) | unquote(msg_var).__struct__.unknown_fields(unquote(msg_var))]}

            unquote(case_return)
        end
      )

    known_tags_case =
      fields
      |> Enum.map(fn {tag, _, name, kind, type} ->
        single = make_single_case(msg_var, syntax, tag, name, kind, type)
        delimited = make_delimited_case(msg_var, syntax, single, tag, name, kind, type)

        delimited ++ single
      end)
      |> List.flatten()

    all_cases = tag_0_case ++ known_tags_case ++ unknown_tag_case

    quote do
      {new_set_fields, field, rest} =
        case Protox.Decode.parse_key(bytes) do
          unquote(all_cases)
        end

      msg_updated = struct(unquote(msg_var), [field])
      parse_key_value(new_set_fields, rest, defs, msg_updated)
    end
  end

  defp make_single_case(_msg_var, _syntax, _tag, _name, _kind, {:message, _}), do: quote(do: [])
  defp make_single_case(_msg_var, _syntax, _tag, _name, _kind, :string), do: quote(do: [])
  defp make_single_case(_msg_var, _syntax, _tag, _name, _kind, :bytes), do: quote(do: [])

  defp make_single_case(_msg_var, _syntax, _tag, _name, _kind, {x, _}) when x != :enum,
    do: quote(do: [])

  defp make_single_case(msg_var, syntax, tag, name, kind, type) do
    bytes_var = quote do: bytes
    field_var = quote do: field
    value_var = quote do: value
    parse_single = make_parse_single(bytes_var, type)
    update_field = make_update_field(name, kind, type, msg_var, value_var)

    # No need to maintain a list of set fields for proto3
    case_return =
      case syntax do
        :proto2 -> quote do: {[unquote(name) | set_fields], unquote(field_var), rest}
        :proto3 -> quote do: {[], unquote(field_var), rest}
      end

    quote do
      {unquote(tag), _, unquote(bytes_var)} ->
        {value, rest} = unquote(parse_single)
        unquote(field_var) = unquote(update_field)
        unquote(case_return)
    end
  end

  defp make_delimited_case(msg_var, syntax, single, tag, name, kind, type = {:message, _}) do
    make_delimited_case_impl(msg_var, syntax, single, tag, name, kind, type)
  end

  defp make_delimited_case(msg_var, syntax, single, tag, name, kind, :bytes) do
    make_delimited_case_impl(msg_var, syntax, single, tag, name, kind, :bytes)
  end

  defp make_delimited_case(msg_var, syntax, single, tag, name, kind, :string) do
    make_delimited_case_impl(msg_var, syntax, single, tag, name, kind, :string)
  end

  defp make_delimited_case(_msg_var, _syntax, _single, _tag, _name, {:default, _}, _) do
    []
  end

  defp make_delimited_case(msg_var, syntax, single, tag, name, kind, type) do
    make_delimited_case_impl(msg_var, syntax, single, tag, name, kind, type)
  end

  defp make_delimited_case_impl(msg_var, syntax, single, tag, name, kind, type) do
    bytes_var = quote do: bytes
    field_var = quote do: field
    value_var = quote do: value
    update_field = make_update_field(name, kind, type, msg_var, value_var)

    case_return =
      case syntax do
        :proto2 -> quote do: {[unquote(name) | set_fields], unquote(field_var), rest}
        :proto3 -> quote do: {[], unquote(field_var), rest}
      end

    delimited_var = quote do: delimited
    parse_delimited = make_parse_delimited(delimited_var, type)

    # If `single` was not generated, then we don't need the `@wire_delimited discrimant
    # as there is only one clause for this `tag`.
    wire_type =
      case single do
        [] -> quote do: _
        _ -> quote do: unquote(@wire_delimited)
      end

    quote do
      {unquote(tag), unquote(wire_type), unquote(bytes_var)} ->
        {len, unquote(bytes_var)} = Protox.Varint.decode(unquote(bytes_var))
        <<unquote(delimited_var)::binary-size(len), rest::binary>> = unquote(bytes_var)
        unquote(value_var) = unquote(parse_delimited)
        unquote(field_var) = unquote(update_field)
        unquote(case_return)
    end
  end

  defp make_update_field(name, :map, _type, msg_var, value_var) do
    quote do
      {entry_key, entry_value} = unquote(value_var)
      {unquote(name), Map.put(unquote(msg_var).unquote(name), entry_key, entry_value)}
    end
  end

  defp make_update_field(name, {:oneof, parent_field}, {:message, _}, msg_var, value_var) do
    quote do
      case unquote(msg_var).unquote(parent_field) do
        {unquote(name), previous_value} ->
          {unquote(parent_field),
           {unquote(name), Protox.Message.merge(previous_value, unquote(value_var))}}

        _ ->
          {unquote(parent_field), {unquote(name), unquote(value_var)}}
      end
    end
  end

  defp make_update_field(name, {:oneof, parent_field}, _type, _msg_var, value_var) do
    quote(do: {unquote(parent_field), {unquote(name), unquote(value_var)}})
  end

  defp make_update_field(name, {:default, _}, {:message, _}, msg_var, value_var) do
    quote do
      {unquote(name), Protox.Message.merge(unquote(msg_var).unquote(name), unquote(value_var))}
    end
  end

  defp make_update_field(name, {:default, _}, _, _msg_var, value_var) do
    quote(do: {unquote(name), unquote(value_var)})
  end

  defp make_update_field(name, _kind, _type, msg_var, value_var) do
    quote do
      {unquote(name), unquote(msg_var).unquote(name) ++ List.wrap(unquote(value_var))}
    end
  end

  defp make_parse_delimited(bytes_var, :bytes) do
    quote(do: unquote(bytes_var))
  end

  defp make_parse_delimited(bytes_var, :string) do
    quote(do: unquote(bytes_var))
  end

  defp make_parse_delimited(bytes_var, {:enum, mod}) do
    quote(do: Protox.Decode.parse_repeated_enum([], unquote(bytes_var), unquote(mod)))
  end

  defp make_parse_delimited(bytes_var, {:message, mod}) do
    quote(do: unquote(mod).decode!(unquote(bytes_var)))
  end

  defp make_parse_delimited(bytes_var, :bool) do
    quote(do: Protox.Decode.parse_repeated_bool([], unquote(bytes_var)))
  end

  defp make_parse_delimited(bytes_var, :int32) do
    quote(do: Protox.Decode.parse_repeated_int32([], unquote(bytes_var)))
  end

  defp make_parse_delimited(bytes_var, :uint32) do
    quote(do: Protox.Decode.parse_repeated_uint32([], unquote(bytes_var)))
  end

  defp make_parse_delimited(bytes_var, :sint32) do
    quote(do: Protox.Decode.parse_repeated_sint32([], unquote(bytes_var)))
  end

  defp make_parse_delimited(bytes_var, :int64) do
    quote(do: Protox.Decode.parse_repeated_int64([], unquote(bytes_var)))
  end

  defp make_parse_delimited(bytes_var, :uint64) do
    quote(do: Protox.Decode.parse_repeated_uint64([], unquote(bytes_var)))
  end

  defp make_parse_delimited(bytes_var, :sint64) do
    quote(do: Protox.Decode.parse_repeated_sint64([], unquote(bytes_var)))
  end

  defp make_parse_delimited(bytes_var, :fixed32) do
    quote(do: Protox.Decode.parse_repeated_fixed32([], unquote(bytes_var)))
  end

  defp make_parse_delimited(bytes_var, :fixed64) do
    quote(do: Protox.Decode.parse_repeated_fixed64([], unquote(bytes_var)))
  end

  defp make_parse_delimited(bytes_var, :sfixed32) do
    quote(do: Protox.Decode.parse_repeated_sfixed32([], unquote(bytes_var)))
  end

  defp make_parse_delimited(bytes_var, :sfixed64) do
    quote(do: Protox.Decode.parse_repeated_sfixed64([], unquote(bytes_var)))
  end

  defp make_parse_delimited(bytes_var, :float) do
    quote(do: Protox.Decode.parse_repeated_float([], unquote(bytes_var)))
  end

  defp make_parse_delimited(bytes_var, :double) do
    quote(do: Protox.Decode.parse_repeated_double([], unquote(bytes_var)))
  end

  defp make_parse_delimited(bytes_var, {key_type, value_type}) do
    unset_map_value =
      case value_type do
        {:message, msg_type} -> quote(do: struct(unquote(msg_type)))
        _ -> quote(do: Protox.Default.default(unquote(value_type)))
      end

    parser_fun_name = make_map_decode_fun_name(key_type, value_type)

    quote do
      {map_key, map_value} = unquote(parser_fun_name)({:unset, :unset}, unquote(bytes_var))

      map_key =
        case map_key do
          :unset -> Protox.Default.default(unquote(key_type))
          _ -> map_key
        end

      map_value =
        case map_value do
          :unset -> unquote(unset_map_value)
          _ -> map_value
        end

      {map_key, map_value}
    end
  end

  defp make_parse_single(bytes_var, :double) do
    quote(do: Protox.Decode.parse_double(unquote(bytes_var)))
  end

  defp make_parse_single(bytes_var, :float) do
    quote(do: Protox.Decode.parse_float(unquote(bytes_var)))
  end

  defp make_parse_single(bytes_var, :sfixed64) do
    quote(do: Protox.Decode.parse_sfixed64(unquote(bytes_var)))
  end

  defp make_parse_single(bytes_var, :fixed64) do
    quote(do: Protox.Decode.parse_fixed64(unquote(bytes_var)))
  end

  defp make_parse_single(bytes_var, :sfixed32) do
    quote(do: Protox.Decode.parse_sfixed32(unquote(bytes_var)))
  end

  defp make_parse_single(bytes_var, :fixed32) do
    quote(do: Protox.Decode.parse_fixed32(unquote(bytes_var)))
  end

  defp make_parse_single(bytes_var, :bool) do
    quote(do: Protox.Decode.parse_bool(unquote(bytes_var)))
  end

  defp make_parse_single(bytes_var, :sint32) do
    quote(do: Protox.Decode.parse_sint32(unquote(bytes_var)))
  end

  defp make_parse_single(bytes_var, :sint64) do
    quote(do: Protox.Decode.parse_sint64(unquote(bytes_var)))
  end

  defp make_parse_single(bytes_var, :uint32) do
    quote(do: Protox.Decode.parse_uint32(unquote(bytes_var)))
  end

  defp make_parse_single(bytes_var, :uint64) do
    quote(do: Protox.Decode.parse_uint64(unquote(bytes_var)))
  end

  defp make_parse_single(bytes_var, :int32) do
    quote(do: Protox.Decode.parse_int32(unquote(bytes_var)))
  end

  defp make_parse_single(bytes_var, :int64) do
    quote(do: Protox.Decode.parse_int64(unquote(bytes_var)))
  end

  defp make_parse_single(bytes_var, {:enum, mod}) do
    quote(do: Protox.Decode.parse_enum(unquote(bytes_var), unquote(mod)))
  end

  defp make_parse_map_entries(fields) do
    {maps, _} = Protox.Defs.split_maps(fields)

    Enum.map(maps, fn {_, _, _, :map, {key_type, value_type}} ->
      bytes_var = quote do: bytes
      rest_var = quote do: rest
      fun_name = make_map_decode_fun_name(key_type, value_type)

      key_parser = make_parse_map_entry(rest_var, key_type)
      value_parser = make_parse_map_entry(rest_var, value_type)

      quote do
        defp unquote(fun_name)(map_entry, <<>>) do
          map_entry
        end

        # https://developers.google.com/protocol-buffers/docs/proto3#backwards-compatibility
        # Maps are equivalent to:
        #   message MapFieldEntry {
        #     key_type key = 1;
        #     value_type value = 2;
        #   }
        # repeated MapFieldEntry map_field = N;
        defp unquote(fun_name)({entry_key, entry_value}, unquote(bytes_var)) do
          {map_entry, unquote(rest_var)} =
            case Protox.Decode.parse_key(unquote(bytes_var)) do
              # key
              {1, _, unquote(rest_var)} ->
                {res, unquote(rest_var)} = unquote(key_parser)
                {{res, entry_value}, unquote(rest_var)}

              # value
              {2, _, unquote(rest_var)} ->
                {res, unquote(rest_var)} = unquote(value_parser)
                {{entry_key, res}, unquote(rest_var)}

              {tag, wire_type, unquote(rest_var)} ->
                {_, unquote(rest_var)} =
                  Protox.Decode.parse_unknown(tag, wire_type, unquote(rest_var))

                {{entry_key, entry_value}, unquote(rest_var)}
            end

          unquote(fun_name)(map_entry, unquote(rest_var))
        end
      end
    end)
  end

  defp make_map_decode_fun_name(key_type, value_type) do
    value_name =
      case value_type do
        {:message, sub_msg} -> "msg_#{Atom.to_string(sub_msg)}"
        {:enum, enum} -> "enum_#{Atom.to_string(enum)}"
        ty -> "#{Atom.to_string(ty)}"
      end

    value_name =
      value_name
      |> Macro.underscore()
      |> String.replace("/", "_")

    String.to_atom("parse_#{Atom.to_string(key_type)}_#{value_name}")
  end

  defp make_parse_map_entry(bytes_var, type) do
    delimited_var = quote do: delimited

    parse_delimited =
      quote do
        {len, new_rest} = Protox.Varint.decode(unquote(bytes_var))
        <<unquote(delimited_var)::binary-size(len), new_rest::binary>> = new_rest
        {unquote(make_parse_delimited(delimited_var, type)), new_rest}
      end

    case type do
      :string -> parse_delimited
      :bytes -> parse_delimited
      {:message, _} -> parse_delimited
      _ -> make_parse_single(bytes_var, type)
    end
  end
end
