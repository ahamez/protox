defmodule Protox.DefineDecoder do
  @moduledoc false
  # Internal. Generates the decoder of a message.

  alias Protox.Field

  use Protox.{
    Float,
    WireTypes
  }

  def define(msg_name, fields, required_fields, opts \\ []) do
    vars = %{
      bytes: Macro.var(:bytes, __MODULE__),
      delimited: Macro.var(:delimited, __MODULE__),
      field: Macro.var(:field, __MODULE__),
      msg: Macro.var(:msg, __MODULE__),
      rest: Macro.var(:rest, __MODULE__),
      set_fields: Macro.var(:set_fields, __MODULE__),
      value: Macro.var(:value, __MODULE__)
    }

    # The public function to decode the binary protobuf.
    decode_fun = make_decode_fun(required_fields, msg_name, vars)

    # The function that decoded the binary protobuf and possibly dispatches to other decoding
    # functions.
    parse_key_value_fun =
      make_parse_key_value_fun(
        required_fields,
        fields,
        vars,
        Keyword.get(opts, :keep_unknown_fields, true)
      )

    # The functions that decode maps.
    parse_map_entries = make_parse_map_entries_funs(vars, fields)

    quote do
      unquote(decode_fun)
      unquote(parse_key_value_fun)
      unquote(parse_map_entries)
    end
  end

  defp make_decode_fun(required_fields, msg_name, vars) do
    decode_bang_fun = make_decode_bang_fun(required_fields, msg_name, vars)

    quote do
      @spec decode(binary) :: {:ok, struct} | {:error, any}
      def decode(bytes) do
        try do
          {:ok, decode!(bytes)}
        rescue
          e in [Protox.DecodingError, Protox.IllegalTagError, Protox.RequiredFieldsError] ->
            {:error, e}
        end
      end

      unquote(decode_bang_fun)
    end
  end

  defp make_decode_bang_fun([], msg_name, _vars) do
    quote do
      @spec decode!(binary) :: struct | no_return
      def decode!(bytes) do
        parse_key_value(bytes, struct(unquote(msg_name)))
      end
    end
  end

  defp make_decode_bang_fun(required_fields, msg_name, vars) do
    quote do
      @spec decode!(binary) :: struct | no_return
      def decode!(bytes) do
        {msg, unquote(vars.set_fields)} = parse_key_value([], bytes, struct(unquote(msg_name)))

        case unquote(required_fields) -- unquote(vars.set_fields) do
          [] -> msg
          missing_fields -> raise Protox.RequiredFieldsError.new(missing_fields)
        end
      end
    end
  end

  defp make_parse_key_value_fun(required_fields, fields, vars, keep_unknown_fields) do
    keep_set_fields = required_fields != []

    parse_key_value_body =
      make_parse_key_value_body(keep_set_fields, fields, vars, keep_unknown_fields)

    if keep_set_fields do
      quote do
        @spec parse_key_value([atom], binary, struct) :: {struct, [atom]}
        defp parse_key_value(unquote(vars.set_fields), <<>>, msg) do
          {msg, unquote(vars.set_fields)}
        end

        defp parse_key_value(unquote(vars.set_fields), bytes, msg) do
          unquote(parse_key_value_body)
        end
      end
    else
      quote do
        @spec parse_key_value(binary, struct) :: struct
        defp parse_key_value(<<>>, msg), do: msg

        defp parse_key_value(bytes, msg), do: unquote(parse_key_value_body)
      end
    end
  end

  defp make_parse_key_value_body(keep_set_fields, fields, vars, keep_unknown_fields) do
    # Fragment to handle the (invalid) field with tag 0.
    tag_0_case = make_parse_key_value_tag_0()

    # Fragment to parse unknown fields. Those are identified with an unknown tag.
    unknown_tag_case = make_parse_key_value_unknown(vars, keep_set_fields, keep_unknown_fields)

    # Fragment to parse known fields.
    known_tags_case = make_parse_key_value_known(vars, fields, keep_set_fields)

    all_cases = tag_0_case ++ known_tags_case ++ unknown_tag_case

    if keep_set_fields do
      quote do
        {new_set_fields, unquote(vars.field), rest} =
          case Protox.Decode.parse_key(bytes) do
            unquote(all_cases)
          end

        msg_updated = struct(unquote(vars.msg), unquote(vars.field))
        parse_key_value(new_set_fields, rest, msg_updated)
      end
    else
      quote do
        {unquote(vars.field), rest} =
          case Protox.Decode.parse_key(bytes) do
            unquote(all_cases)
          end

        msg_updated = struct(unquote(vars.msg), unquote(vars.field))
        parse_key_value(rest, msg_updated)
      end
    end
  end

  defp make_parse_key_value_tag_0() do
    quote do
      {0, _, _} -> raise %Protox.IllegalTagError{}
    end
  end

  defp make_parse_key_value_known(vars, fields, keep_set_fields) do
    fields
    |> Enum.map(fn %Field{} = field ->
      single = make_single_case(vars, keep_set_fields, field)

      single_generated = single != []
      delimited = make_delimited_case(vars, keep_set_fields, single_generated, field)

      delimited ++ single
    end)
    |> List.flatten()
  end

  defp make_parse_key_value_unknown(vars, keep_set_fields, true = _keep_unknown_fields) do
    body =
      quote do
        {unquote(vars.msg).__struct__.unknown_fields_name(),
         [
           unquote(vars.value)
           | unquote(vars.msg).__struct__.unknown_fields(unquote(vars.msg))
         ]}
      end

    case_return =
      case keep_set_fields do
        true -> quote(do: {unquote(vars.set_fields), [unquote(body)], rest})
        # No need to maintain a list of set fields when the list of required fields is empty
        false -> quote(do: {[unquote(body)], rest})
      end

    quote do
      {tag, wire_type, rest} ->
        {unquote(vars.value), rest} = Protox.Decode.parse_unknown(tag, wire_type, rest)

        unquote(case_return)
    end
  end

  defp make_parse_key_value_unknown(vars, keep_set_fields, false = _keep_unknown_fields) do
    # No need to maintain a list of set fields when the list of required fields is empty
    case_return =
      case keep_set_fields do
        true -> quote do: {unquote(vars.set_fields), [], rest}
        false -> quote do: {[], rest}
      end

    quote do
      {tag, wire_type, rest} ->
        {_, rest} = Protox.Decode.parse_unknown(tag, wire_type, rest)

        unquote(case_return)
    end
  end

  defp make_single_case(_vars, _keep_set_fields, %Field{type: {:message, _}}) do
    quote(do: [])
  end

  defp make_single_case(_vars, _keep_set_fields, %Field{type: :string}), do: quote(do: [])
  defp make_single_case(_vars, _keep_set_fields, %Field{type: :bytes}), do: quote(do: [])

  defp make_single_case(_vars, _keep_set_fields, %Field{type: {x, _}}) when x != :enum do
    quote(do: [])
  end

  defp make_single_case(vars, keep_set_fields, %Field{} = field) do
    parse_single = make_parse_single(vars.bytes, field.type)
    update_field = make_update_field(vars.value, field, vars, _wrap_value = true)

    # No need to maintain a list of set fields for proto3
    case_return =
      case keep_set_fields do
        true ->
          quote do: {[unquote(field.name) | set_fields], [unquote(update_field)], rest}

        false ->
          quote do: {[unquote(update_field)], rest}
      end

    quote do
      {unquote(field.tag), _, unquote(vars.bytes)} ->
        {value, rest} = unquote(parse_single)
        unquote(case_return)
    end
  end

  defp make_delimited_case(
         vars,
         keep_set_fields,
         single_generated,
         %Field{type: {:message, _}} = field
       ) do
    make_delimited_case_impl(vars, keep_set_fields, single_generated, field)
  end

  defp make_delimited_case(vars, keep_set_fields, single_generated, %Field{type: :bytes} = field) do
    make_delimited_case_impl(vars, keep_set_fields, single_generated, field)
  end

  defp make_delimited_case(vars, keep_set_fields, single_generated, %Field{type: :string} = field) do
    make_delimited_case_impl(vars, keep_set_fields, single_generated, field)
  end

  defp make_delimited_case(_vars, _keep_set_fields, _single_generated, %Field{kind: {:scalar, _}}) do
    []
  end

  defp make_delimited_case(_vars, _keep_set_fields, _single_generated, %Field{kind: {:oneof, _}}) do
    []
  end

  defp make_delimited_case(vars, keep_set_fields, single_generated, %Field{} = field) do
    make_delimited_case_impl(vars, keep_set_fields, single_generated, field)
  end

  defp make_delimited_case_impl(vars, keep_set_fields, single_generated, %Field{} = field) do
    # If the case to decode single occurrences of repeated elements has been generated,
    # it means that it's a repeated field of scalar elements (as non-scalar cannot be packed,
    # see https://developers.google.com/protocol-buffers/docs/encoding#optional).
    # Thus, it's useless to wrap in a list the result of the decoding as it means
    # we're using a parse_repeated_* function that always returns a list.
    update_field =
      if field.type == :bytes do
        make_update_field(vars.delimited, field, vars, _wrap_value = !single_generated)
      else
        parse_delimited = make_parse_delimited(vars.delimited, field.type)
        make_update_field(parse_delimited, field, vars, _wrap_value = !single_generated)
      end

    case_return =
      case keep_set_fields do
        true -> quote do: {[unquote(field.name) | set_fields], [unquote(update_field)], rest}
        false -> quote do: {[unquote(update_field)], rest}
      end

    # If `single` was not generated, then we don't need the `@wire_delimited discrimant
    # as there is only one clause for this `tag`.
    wire_type =
      case single_generated do
        true -> quote do: unquote(@wire_delimited)
        false -> quote do: _
      end

    quote do
      {unquote(field.tag), unquote(wire_type), unquote(vars.bytes)} ->
        {len, unquote(vars.bytes)} = Protox.Varint.decode(unquote(vars.bytes))
        {unquote(vars.delimited), rest} = Protox.Decode.parse_delimited(unquote(vars.bytes), len)
        unquote(case_return)
    end
  end

  defp make_update_field(value, %Field{kind: :map} = field, vars, _wrap_value) do
    quote do
      {entry_key, entry_value} = unquote(value)

      {unquote(field.name),
       Map.put(unquote(vars.msg).unquote(field.name), entry_key, entry_value)}
    end
  end

  defp make_update_field(
         value,
         %Field{label: :proto3_optional, kind: {:oneof, _}, type: {:message, _}} = field,
         vars,
         _wrap_value
       ) do
    quote do
      case unquote(vars.msg).unquote(field.name) do
        {unquote(field.name), previous_value} ->
          {unquote(field.name), Protox.MergeMessage.merge(previous_value, unquote(value))}

        _ ->
          {unquote(field.name), unquote(value)}
      end
    end
  end

  defp make_update_field(
         value,
         %Field{kind: {:oneof, parent_field}, type: {:message, _}} = field,
         vars,
         _wrap_value
       ) do
    quote do
      case unquote(vars.msg).unquote(parent_field) do
        {unquote(field.name), previous_value} ->
          {unquote(parent_field),
           {unquote(field.name), Protox.MergeMessage.merge(previous_value, unquote(value))}}

        _ ->
          {unquote(parent_field), {unquote(field.name), unquote(value)}}
      end
    end
  end

  defp make_update_field(value, %Field{kind: {:oneof, parent_field}} = field, _vars, _wrap_value) do
    case field.label do
      :proto3_optional ->
        quote(do: {unquote(field.name), unquote(value)})

      _ ->
        quote(do: {unquote(parent_field), {unquote(field.name), unquote(value)}})
    end
  end

  defp make_update_field(
         value,
         %Field{kind: {:scalar, _}, type: {:message, _}} = field,
         vars,
         _wrap_value
       ) do
    quote do
      {
        unquote(field.name),
        Protox.MergeMessage.merge(unquote(vars.msg).unquote(field.name), unquote(value))
      }
    end
  end

  defp make_update_field(value, %Field{kind: {:scalar, _}} = field, _vars, _wrap_value) do
    quote(do: {unquote(field.name), unquote(value)})
  end

  defp make_update_field(value, %Field{} = field, vars, true = _wrap_value) do
    quote do
      {unquote(field.name), unquote(vars.msg).unquote(field.name) ++ [unquote(value)]}
    end
  end

  defp make_update_field(value, %Field{} = field, vars, false = _wrap_value) do
    quote do
      {unquote(field.name), unquote(vars.msg).unquote(field.name) ++ unquote(value)}
    end
  end

  defp make_parse_delimited(bytes_var, :bytes) do
    quote(do: unquote(bytes_var))
  end

  defp make_parse_delimited(bytes_var, :string) do
    quote(do: Protox.Decode.validate_string!(unquote(bytes_var)))
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

  defp make_parse_map_entries_funs(vars, fields) do
    {maps, _other_fields} = Protox.Defs.split_maps(fields)

    maps
    |> Enum.map(fn %Field{kind: :map} = field ->
      key_type = elem(field.type, 0)
      value_type = elem(field.type, 1)

      fun_name = make_map_decode_fun_name(key_type, value_type)

      key_parser = make_parse_map_entry(vars, key_type)
      value_parser = make_parse_map_entry(vars, value_type)

      code =
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
          #
          defp unquote(fun_name)({entry_key, entry_value}, unquote(vars.bytes)) do
            {map_entry, unquote(vars.rest)} =
              case Protox.Decode.parse_key(unquote(vars.bytes)) do
                # key
                {1, _, unquote(vars.rest)} ->
                  {res, unquote(vars.rest)} = unquote(key_parser)
                  {{res, entry_value}, unquote(vars.rest)}

                # value
                {2, _, unquote(vars.rest)} ->
                  {res, unquote(vars.rest)} = unquote(value_parser)
                  {{entry_key, res}, unquote(vars.rest)}

                {tag, wire_type, unquote(vars.rest)} ->
                  {_, unquote(vars.rest)} =
                    Protox.Decode.parse_unknown(tag, wire_type, unquote(vars.rest))

                  {{entry_key, entry_value}, unquote(vars.rest)}
              end

            unquote(fun_name)(map_entry, unquote(vars.rest))
          end
        end

      {fun_name, code}
    end)
    |> Enum.sort(fn {lhs_fun_name, _}, {rhs_fun_name, _} -> lhs_fun_name < rhs_fun_name end)
    |> Enum.dedup_by(fn {fun_name, _} -> fun_name end)
    |> Enum.map(fn {_, code} -> code end)
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

  defp make_parse_map_entry(vars, type) do
    parse_delimited =
      quote do
        {len, new_rest} = Protox.Varint.decode(unquote(vars.rest))
        {unquote(vars.delimited), new_rest} = Protox.Decode.parse_delimited(new_rest, len)

        {unquote(make_parse_delimited(vars.delimited, type)), new_rest}
      end

    case type do
      :string -> parse_delimited
      :bytes -> parse_delimited
      {:message, _} -> parse_delimited
      _ -> make_parse_single(vars.rest, type)
    end
  end
end
