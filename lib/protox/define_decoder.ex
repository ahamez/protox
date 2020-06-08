defmodule Protox.DefineDecoder do
  @moduledoc false
  # Internal. Generates the decoder of a message.

  use Protox.Float
  use Protox.WireTypes

  def define(msg_name, fields, required_fields, syntax) do
    make_decode(msg_name, fields, required_fields, syntax)
  end

  # -- Private

  defp make_decode(msg_name, [], _, _) do
    quote do
      @spec decode_meta(binary) :: {:ok, struct} | {:error, any}
      def decode_meta(_msg), do: {:ok, struct(unquote(msg_name))}

      @spec decode_meta!(binary) :: struct | no_return
      def decode_meta!(_msg), do: struct(unquote(msg_name))
    end
  end

  defp make_decode(msg_name, fields, required_fields, syntax) do
    decode_return = make_decode_return(syntax, required_fields)
    parse_key_value = make_parse_key_value(syntax, fields)

    quote do
      @spec decode_meta(binary) :: {:ok, struct} | {:error, any}
      def decode_meta(bytes) do
        try do
          {:ok, decode_meta!(bytes)}
        rescue
          e -> {:error, e}
        end
      end

      @spec decode_meta!(binary) :: struct | no_return
      def decode_meta!(bytes) do
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
    end
  end

  defp make_decode_return(:proto2, required_fields) do
    quote do
      case unquote(required_fields) -- set_fields do
        [] -> msg
        missing_fields -> raise Protox.RequiredFieldsError.new(missing_fields)
      end
    end
  end

  # No need to check for missing required fields for Protobuf 3
  defp make_decode_return(:proto3, _required_fields) do
    quote do
      msg
    end
  end

  defp make_parse_key_value(syntax, fields) do
    tag_0_case =
      quote do
        {0, _, _} -> raise "Illegal field with tag 0"
      end

    unknown_tag_case =
      (
        case_return =
          case syntax do
            :proto2 -> quote do: {set_fields, field, new_rest}
            :proto3 -> quote do: {[], field, new_rest}
          end

        quote do
          {tag, wire_type, rest} ->
            {value, new_rest} = Protox.Decode.parse_unknown(tag, wire_type, rest)

            field =
              Protox.Decode.update_field(
                msg,
                msg.__struct__.unknown_fields_name(),
                nil,
                value,
                nil
              )

            unquote(case_return)
        end
      )

    known_tags_case =
      Enum.map(fields, fn {tag, _, name, kind, type} ->
        single = make_single_case(syntax, tag, name, kind, type)
        delimited = make_delimited_case(syntax, single, tag, name, kind, type)

        delimited ++ single
      end)
      |> List.flatten()

    all_cases = tag_0_case ++ known_tags_case ++ unknown_tag_case

    quote do
      {new_set_fields, field, new_rest} =
        case Protox.Decode.parse_key(bytes) do
          unquote(all_cases)
        end

      msg_updated = struct(msg, [field])
      parse_key_value(new_set_fields, new_rest, defs, msg_updated)
    end
  end

  defp make_single_case(_syntax, _tag, _name, _kind, {:message, _}), do: quote(do: [])
  defp make_single_case(_syntax, _tag, _name, _kind, :string), do: quote(do: [])
  defp make_single_case(_syntax, _tag, _name, _kind, :bytes), do: quote(do: [])
  defp make_single_case(_syntax, _tag, _name, _kind, {x, _}) when x != :enum, do: quote(do: [])

  defp make_single_case(syntax, tag, name, kind, type) do
    bytes_var = quote do: bytes
    field_var = quote do: field
    parse_single = make_parse_single(bytes_var, type)

    case_return =
      case syntax do
        :proto2 -> quote do: {[unquote(name) | set_fields], unquote(field_var), new_rest}
        :proto3 -> quote do: {[], unquote(field_var), new_rest}
      end

    quote do
      {unquote(tag), _, unquote(bytes_var)} ->
        {value, new_rest} = unquote(parse_single)

        unquote(field_var) =
          Protox.Decode.update_field(
            msg,
            unquote(name),
            unquote(kind),
            value,
            unquote(type)
          )

        # msg_updated = struct(msg, [field])
        unquote(case_return)
    end
  end

  defp make_delimited_case(syntax, single, tag, name, kind, type = {:message, _}) do
    make_delimited_case_impl(syntax, single, tag, name, kind, type)
  end

  defp make_delimited_case(syntax, single, tag, name, kind, :bytes) do
    make_delimited_case_impl(syntax, single, tag, name, kind, :bytes)
  end

  defp make_delimited_case(syntax, single, tag, name, kind, :string) do
    make_delimited_case_impl(syntax, single, tag, name, kind, :string)
  end

  defp make_delimited_case(_syntax, _single, _tag, _name, {:default, _}, _) do
    []
  end

  defp make_delimited_case(syntax, single, tag, name, kind, type) do
    make_delimited_case_impl(syntax, single, tag, name, kind, type)
  end

  defp make_delimited_case_impl(syntax, single, tag, name, kind, type) do
    field_var = quote do: field

    case_return =
      case syntax do
        :proto2 -> quote do: {[unquote(name) | set_fields], unquote(field_var), new_rest}
        :proto3 -> quote do: {[], unquote(field_var), new_rest}
      end

    delimited_var = quote do: delimited
    parse_delimited = make_parse_delimited(delimited_var, type)

    wire_type =
      if single == [] do
        quote do: _
      else
        quote do: unquote(@wire_delimited)
      end

    quote do
      {unquote(tag), unquote(wire_type), bytes} ->
        {len, new_bytes} = Protox.Varint.decode(bytes)
        <<delimited::binary-size(len), new_rest::binary>> = new_bytes
        value = unquote(parse_delimited)

        field =
          Protox.Decode.update_field(
            msg,
            unquote(name),
            unquote(kind),
            value,
            unquote(type)
          )

        # msg_updated = struct(msg, [field])
        unquote(case_return)
    end
  end

  defp make_parse_delimited(delimited_var, :bytes) do
    quote do
      unquote(delimited_var)
    end
  end

  defp make_parse_delimited(delimited_var, :string) do
    quote do
      unquote(delimited_var)
    end
  end

  defp make_parse_delimited(delimited_var, {:enum, mod}) do
    quote do
      Protox.Decode.parse_repeated_enum([], unquote(delimited_var), unquote(mod))
    end
  end

  defp make_parse_delimited(delimited_var, {:message, mod}) do
    quote do
      Protox.Decode.decode!(unquote(delimited_var), unquote(mod), unquote(mod).required_fields())
    end
  end

  defp make_parse_delimited(delimited_var, :bool) do
    quote do
      Protox.Decode.parse_repeated_bool([], unquote(delimited_var))
    end
  end

  defp make_parse_delimited(delimited_var, :int32) do
    quote do
      Protox.Decode.parse_repeated_int32([], unquote(delimited_var))
    end
  end

  defp make_parse_delimited(delimited_var, :uint32) do
    quote do
      Protox.Decode.parse_repeated_uint32([], unquote(delimited_var))
    end
  end

  defp make_parse_delimited(delimited_var, :sint32) do
    quote do
      Protox.Decode.parse_repeated_sint32([], unquote(delimited_var))
    end
  end

  defp make_parse_delimited(delimited_var, :int64) do
    quote do
      Protox.Decode.parse_repeated_int64([], unquote(delimited_var))
    end
  end

  defp make_parse_delimited(delimited_var, :uint64) do
    quote do
      Protox.Decode.parse_repeated_uint64([], unquote(delimited_var))
    end
  end

  defp make_parse_delimited(delimited_var, :sint64) do
    quote do
      Protox.Decode.parse_repeated_sint64([], unquote(delimited_var))
    end
  end

  defp make_parse_delimited(delimited_var, :fixed32) do
    quote do
      Protox.Decode.parse_repeated_fixed32([], unquote(delimited_var))
    end
  end

  defp make_parse_delimited(delimited_var, :fixed64) do
    quote do
      Protox.Decode.parse_repeated_fixed64([], unquote(delimited_var))
    end
  end

  defp make_parse_delimited(delimited_var, :sfixed32) do
    quote do
      Protox.Decode.parse_repeated_sfixed32([], unquote(delimited_var))
    end
  end

  defp make_parse_delimited(delimited_var, :sfixed64) do
    quote do
      Protox.Decode.parse_repeated_sfixed64([], unquote(delimited_var))
    end
  end

  defp make_parse_delimited(delimited_var, :float) do
    quote do
      Protox.Decode.parse_repeated_float([], unquote(delimited_var))
    end
  end

  defp make_parse_delimited(delimited_var, :double) do
    quote do
      Protox.Decode.parse_repeated_double([], unquote(delimited_var))
    end
  end

  defp make_parse_delimited(delimited_var, type) do
    quote do
      Protox.Decode.parse_delimited(unquote(delimited_var), unquote(type))
    end
  end

  defp make_parse_single(bytes_var, :double) do
    quote do
      Protox.Decode.parse_double(unquote(bytes_var))
    end
  end

  defp make_parse_single(bytes_var, :float) do
    quote do
      Protox.Decode.parse_float(unquote(bytes_var))
    end
  end

  defp make_parse_single(bytes_var, :sfixed64) do
    quote do
      Protox.Decode.parse_sfixed64(unquote(bytes_var))
    end
  end

  defp make_parse_single(bytes_var, :fixed64) do
    quote do
      Protox.Decode.parse_fixed64(unquote(bytes_var))
    end
  end

  defp make_parse_single(bytes_var, :sfixed32) do
    quote do
      Protox.Decode.parse_sfixed32(unquote(bytes_var))
    end
  end

  defp make_parse_single(bytes_var, :fixed32) do
    quote do
      Protox.Decode.parse_fixed32(unquote(bytes_var))
    end
  end

  defp make_parse_single(bytes_var, :bool) do
    quote do
      Protox.Decode.parse_bool(unquote(bytes_var))
    end
  end

  defp make_parse_single(bytes_var, :sint32) do
    quote do
      Protox.Decode.parse_sint32(unquote(bytes_var))
    end
  end

  defp make_parse_single(bytes_var, :sint64) do
    quote do
      Protox.Decode.parse_sint64(unquote(bytes_var))
    end
  end

  defp make_parse_single(bytes_var, :uint32) do
    quote do
      Protox.Decode.parse_uint32(unquote(bytes_var))
    end
  end

  defp make_parse_single(bytes_var, :uint64) do
    quote do
      Protox.Decode.parse_uint64(unquote(bytes_var))
    end
  end

  defp make_parse_single(bytes_var, :int32) do
    quote do
      Protox.Decode.parse_int32(unquote(bytes_var))
    end
  end

  defp make_parse_single(bytes_var, :int64) do
    quote do
      Protox.Decode.parse_int64(unquote(bytes_var))
    end
  end

  defp make_parse_single(bytes_var, {:enum, mod}) do
    quote do
      Protox.Decode.parse_enum(unquote(bytes_var), unquote(mod))
    end
  end
end
