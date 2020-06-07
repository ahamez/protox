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
        delimited =
          quote do
            {unquote(tag), unquote(@wire_delimited), bytes} ->
              {len, new_bytes} = Protox.Varint.decode(bytes)
              <<delimited::binary-size(len), new_rest::binary>> = new_bytes
              value = Protox.Decode.parse_delimited(delimited, unquote(type))

              field =
                Protox.Decode.update_field(
                  msg,
                  unquote(name),
                  unquote(kind),
                  value,
                  unquote(type)
                )

              msg_updated = struct(msg, [field])
              {[unquote(name) | set_fields], msg_updated, new_rest}
          end

        single =
          case type do
            {:message, _} ->
              []

            :string ->
              []

            :bytes ->
              []

            # map
            {x, _} when x != :enum ->
              []

            _ ->
              parse_single = make_parse_single(type)

              quote do
                {unquote(tag), _, bytes} ->
                  {value, new_rest} = unquote(parse_single)

                  field =
                    Protox.Decode.update_field(
                      msg,
                      unquote(name),
                      unquote(kind),
                      value,
                      unquote(type)
                    )

                  msg_updated = struct(msg, [field])
                  {[unquote(name) | set_fields], msg_updated, new_rest}
              end
          end

        delimited ++ single
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

  defp make_parse_single(:double) do
    quote do
      case bytes do
        <<unquote(@positive_infinity_64), rest::binary>> -> {:infinity, rest}
        <<unquote(@negative_infinity_64), rest::binary>> -> {:"-infinity", rest}
        <<_::48, 0b1111::4, _::4, _::1, 0b1111111::7, rest::binary>> -> {:nan, rest}
        <<value::float-little-64, rest::binary>> -> {value, rest}
      end
    end
  end

  defp make_parse_single(:float) do
    quote do
      case bytes do
        <<unquote(@positive_infinity_32), rest::binary>> -> {:infinity, rest}
        <<unquote(@negative_infinity_32), rest::binary>> -> {:"-infinity", rest}
        <<_::16, 1::1, _::7, _::1, 0b1111111::7, rest::binary>> -> {:nan, rest}
        <<value::float-little-32, rest::binary>> -> {value, rest}
      end
    end
  end

  defp make_parse_single(:sfixed64) do
    quote do
      <<value::signed-little-64, rest::binary>> = bytes
      {value, rest}
    end
  end

  defp make_parse_single(:fixed64) do
    quote do
      <<value::signed-little-64, rest::binary>> = bytes
      {value, rest}
    end
  end

  defp make_parse_single(:sfixed32) do
    quote do
      <<value::signed-little-32, rest::binary>> = bytes
      {value, rest}
    end
  end

  defp make_parse_single(:fixed32) do
    quote do
      <<value::signed-little-32, rest::binary>> = bytes
      {value, rest}
    end
  end

  defp make_parse_single(:bool) do
    quote do
      {value, rest} = Protox.Varint.decode(bytes)
      {value != 0, rest}
    end
  end

  defp make_parse_single(:sint32) do
    quote do
      {value, rest} = Protox.Varint.decode(bytes)
      <<res::unsigned-native-32>> = <<value::unsigned-native-32>>
      {Protox.Zigzag.decode(res), rest}
    end
  end

  defp make_parse_single(:sint64) do
    quote do
      {value, rest} = Protox.Varint.decode(bytes)
      <<res::unsigned-native-64>> = <<value::unsigned-native-64>>
      {Protox.Zigzag.decode(res), rest}
    end
  end

  defp make_parse_single(:uint32) do
    quote do
      {value, rest} = Protox.Varint.decode(bytes)
      <<res::unsigned-native-32>> = <<value::unsigned-native-32>>
      {res, rest}
    end
  end

  defp make_parse_single(:uint64) do
    quote do
      {value, rest} = Protox.Varint.decode(bytes)
      <<res::unsigned-native-64>> = <<value::unsigned-native-64>>
      {res, rest}
    end
  end

  defp make_parse_single(:int32) do
    quote do
      {value, rest} = Protox.Varint.decode(bytes)
      <<res::signed-native-32>> = <<value::signed-native-32>>
      {res, rest}
    end
  end

  defp make_parse_single(:int64) do
    quote do
      {value, rest} = Protox.Varint.decode(bytes)
      <<res::signed-native-64>> = <<value::signed-native-64>>
      {res, rest}
    end
  end

  defp make_parse_single({:enum, mod}) do
    quote do
      {value, rest} = Protox.Varint.decode(bytes)
      <<res::signed-native-32>> = <<value::signed-native-32>>
      {unquote(mod).decode(res), rest}
    end
  end
end
