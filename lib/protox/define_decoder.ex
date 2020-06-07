defmodule Protox.DefineDecoder do
  @moduledoc false
  # Internal. Generates the decoder of a message.

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
    parse_key_value = make_parse_key_value(fields)

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

  defp make_parse_key_value(fields) do
    tag_0_case =
      quote do
        {0, _, _} -> raise "Illegal field with tag 0"
      end

    unknwon_tag_case =
      quote do
        {tag, wire_type, rest} ->
          {new_msg, new_rest} = Protox.Decode.parse_unknown(msg, tag, wire_type, rest)
          {set_fields, new_msg, new_rest}
      end

    known_tags_case =
      Enum.map(fields, fn {tag, _, name, kind, type} ->
        quote do
          {unquote(tag), wire_type, rest} ->
            {value, new_rest} = Protox.Decode.parse_value(rest, wire_type, unquote(type))
            field = Protox.Decode.update_field(msg, unquote(name), unquote(kind), value, unquote(type))
            msg_updated = struct!(msg, [field])
            {[unquote(name) | set_fields], msg_updated, new_rest}
        end
      end)
      |> List.flatten()

    all_cases = tag_0_case ++ known_tags_case ++ unknwon_tag_case

    quote do
      {new_set_fields, new_msg, new_rest} =
        case Protox.Decode.parse_key(bytes) do
          unquote(all_cases)
        end

      parse_key_value(new_set_fields, new_rest, defs, new_msg)
    end
  end
end
