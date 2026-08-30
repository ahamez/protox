defmodule Protox.DefineDecoder do
  @moduledoc false
  # Internal. Generates the decoder of a message.
  use Protox.{Float, WireTypes}

  alias Protox.{Field, OneOf, Scalar}

  @spec define(atom(), [Field.t()], keyword()) :: Macro.t()
  def define(msg_name, fields, opts \\ []) do
    vars = %{
      bytes: Macro.var(:bytes, __MODULE__),
      delimited: Macro.var(:delimited, __MODULE__),
      msg: Macro.var(:msg, __MODULE__),
      rest: Macro.var(:rest, __MODULE__),
      set_fields: Macro.var(:set_fields, __MODULE__),
      value: Macro.var(:value, __MODULE__)
    }

    # The public function to decode the binary protobuf.
    decode_fun = make_decode_fun(msg_name, vars)

    # The function that decodes the binary protobuf and possibly dispatches to other decoding
    # functions.
    parse_key_value_fun = make_parse_key_value_fun(fields, vars, opts)

    # The functions that decodes maps.
    parse_map_entries = make_parse_map_entries_funs(vars, fields)

    quote do
      unquote(decode_fun)
      unquote(parse_key_value_fun)
      unquote_splicing(parse_map_entries)
    end
  end

  defp make_decode_fun(msg_name, vars) do
    decode_bang_fun = make_decode_bang_fun(msg_name, vars)

    quote do
      @spec decode(binary()) :: {:ok, t()} | {:error, any()}
      def decode(bytes) do
        {:ok, decode!(bytes)}
      rescue
        e in [Protox.DecodingError, Protox.IllegalTagError, Protox.RequiredFieldsError] ->
          {:error, e}
      end

      unquote(decode_bang_fun)
    end
  end

  defp make_decode_bang_fun(_msg_name, _vars) do
    quote do
      @spec decode!(binary()) :: t() | no_return()
      def decode!(bytes) do
        parse_key_value(bytes, __struct__())
      end
    end
  end

  defp make_parse_key_value_fun(fields, vars, opts) do
    parse_key_value_body =
      make_parse_key_value_body(fields, vars, opts)

    unknown_fields_name = Keyword.fetch!(opts, :unknown_fields_name)
    finish_decode = make_finish_decode(fields, vars.msg, unknown_fields_name)

    quote do
      @spec parse_key_value(binary(), struct()) :: struct()
      defp parse_key_value(<<>>, msg) do
        unquote(finish_decode)
      end

      defp parse_key_value(bytes, msg), do: unquote(parse_key_value_body)
    end
  end

  defp make_finish_decode(fields, msg_var, unknown_fields_name) do
    repeated_field_names =
      fields
      |> Enum.filter(&(&1.kind in [:packed, :unpacked]))
      |> Enum.map(& &1.name)
      |> Enum.uniq()

    # Update only the fields that need it: repeated fields are most often empty
    # or hold a single element (which is order-invariant), and skipping them
    # avoids both the reverse call and the struct update. The last update is the
    # block's value, not a rebind: a final rebind would trigger an
    # unused-variable warning in the generated code.
    update = fn field_name ->
      quote do
        case unquote(msg_var).unquote(field_name) do
          [_first, _second | _tail] = values -> %{unquote(msg_var) | unquote(field_name) => :lists.reverse(values)}
          _empty_or_single -> unquote(msg_var)
        end
      end
    end

    {init_field_names, [last_field_name]} =
      Enum.split(repeated_field_names ++ [unknown_fields_name], -1)

    rebinds =
      Enum.map(init_field_names, fn field_name ->
        quote do
          unquote(msg_var) = unquote(update.(field_name))
        end
      end)

    quote do
      (unquote_splicing(rebinds ++ [update.(last_field_name)]))
    end
  end

  defp make_parse_key_value_body(fields, vars, opts) do
    # Fragment to parse unknown fields. Those are identified with an unknown tag.
    unknown_tag_clause =
      make_parse_key_value_unknown(vars, Keyword.fetch!(opts, :unknown_fields_name))

    # Fragment to parse all regular fields.
    all_fields_clause = make_parse_key_value_known(vars, fields)

    all_clauses =
      make_parse_key_value_invalid_varint() ++
        make_parse_key_value_tag_0() ++
        all_fields_clause ++
        unknown_tag_clause

    # Note we directly pattern-match against the bytes: we don't decode the tag
    # and the wire type using Varint.decode. Indeed, as we know the varint encoding
    # at compile time, we can generate the appropriate clauses.
    # This has the benefit of a small speedup (~1%-10%) and a decrease in memory usage (~10%) from
    # the Varint.decode version.
    quote do
      case bytes, do: unquote(all_clauses)
    end
  end

  defp make_parse_key_value_tag_0() do
    quote do
      <<0::5, _wire_type::3, _rest::binary>> -> raise %Protox.IllegalTagError{}
    end
  end

  defp make_parse_key_value_invalid_varint() do
    quote do
      <<_tag::5, 3::3, _rest::binary>> ->
        raise Protox.DecodingError.new(bytes, "invalid wire type 3")

      <<_tag::5, 4::3, _rest::binary>> ->
        raise Protox.DecodingError.new(bytes, "invalid wire type 4")

      <<_tag::5, 6::3, _rest::binary>> ->
        raise Protox.DecodingError.new(bytes, "invalid wire type 6")

      <<_tag::5, 7::3, _rest::binary>> ->
        raise Protox.DecodingError.new(bytes, "invalid wire type 7")
    end
  end

  defp make_parse_key_value_known(vars, fields) do
    Enum.flat_map(fields, fn %Field{} = field ->
      single = make_single_case(vars, field)

      single_generated = single != []
      delimited = make_delimited_case(vars, single_generated, field)

      delimited ++ single
    end)
  end

  defp make_parse_key_value_unknown(vars, unknown_fields_name) do
    quote do
      <<unquote(vars.bytes)::binary>> ->
        {tag, wire_type, rest} = Protox.Decode.parse_key(unquote(vars.bytes))
        {unquote(vars.value), rest} = Protox.Decode.parse_unknown(tag, wire_type, rest)

        unquote(vars.msg) = %{
          unquote(vars.msg)
          | unquote(unknown_fields_name) => [
              unquote(vars.value) | unquote(vars.msg).unquote(unknown_fields_name)
            ]
        }

        parse_key_value(rest, unquote(vars.msg))
    end
  end

  defp make_single_case(_vars, %Field{type: :string}), do: quote(do: [])
  defp make_single_case(_vars, %Field{type: :bytes}), do: quote(do: [])
  defp make_single_case(_vars, %Field{type: {x, _sub_type}}) when x != :enum, do: quote(do: [])

  defp make_single_case(vars, %Field{} = field) do
    parse_single = make_parse_single(vars.bytes, field.type)
    update_field = make_update_field(vars.value, field, vars, _wrap_value = true)

    # Match the full literal key (tag and wire type): the BEAM can then dispatch
    # on whole bytes, and a known tag with an unexpected wire type falls through
    # to the unknown-field clause instead of being misparsed. The wire type comes
    # from the element type, not the field kind: for repeated fields this clause
    # decodes single (unpacked) occurrences, whose key differs from the packed one.
    key_bytes = make_literal_key_bytes(field.tag, field.type)

    fast_case = make_single_fast_case(vars, field, key_bytes, update_field)

    general_case =
      quote do
        <<unquote(key_bytes), unquote(vars.bytes)::binary>> ->
          {value, rest} = unquote(parse_single)
          unquote(vars.msg) = unquote(update_field)
          parse_key_value(rest, unquote(vars.msg))
      end

    fast_case ++ general_case
  end

  # For varint-encoded scalars, a clause matching the very common one-byte value
  # in the key pattern itself skips the Protox.Decode.parse_* call and the
  # {value, rest} tuple it returns. Larger values fall through to the general
  # clause right after.
  #
  # Unlike the general path, no truncate_* step is applied: the one-byte pattern
  # bounds varint_value to 0..127, where every truncation is an identity. That
  # invariant is what makes these transforms sound — extending the fast case
  # beyond one-byte varints would require restoring the truncations.
  defp make_single_fast_case(vars, %Field{type: :bool}, key_bytes, update_field) do
    make_single_fast_case_clause(vars, key_bytes, update_field, quote(do: varint_value != 0))
  end

  defp make_single_fast_case(vars, %Field{type: {:enum, mod}}, key_bytes, update_field) do
    make_single_fast_case_clause(vars, key_bytes, update_field, quote(do: unquote(mod).decode(varint_value)))
  end

  defp make_single_fast_case(vars, %Field{type: type}, key_bytes, update_field) when type in [:sint32, :sint64] do
    make_single_fast_case_clause(vars, key_bytes, update_field, quote(do: Protox.Zigzag.decode(varint_value)))
  end

  defp make_single_fast_case(vars, %Field{type: type}, key_bytes, update_field)
       when type in [:int32, :int64, :uint32, :uint64] do
    make_single_fast_case_clause(vars, key_bytes, update_field, quote(do: varint_value))
  end

  defp make_single_fast_case(_vars, _field, _key_bytes, _update_field), do: []

  defp make_single_fast_case_clause(vars, key_bytes, update_field, value) do
    quote do
      <<unquote(key_bytes), 0::1, varint_value::7, rest::binary>> ->
        unquote(vars.value) = unquote(value)
        unquote(vars.msg) = unquote(update_field)
        parse_key_value(rest, unquote(vars.msg))
    end
  end

  defp make_delimited_case(vars, single_generated, %Field{type: {:message, _msg_type}} = field) do
    make_delimited_case_impl(vars, single_generated, field)
  end

  defp make_delimited_case(vars, single_generated, %Field{type: :bytes} = field) do
    make_delimited_case_impl(vars, single_generated, field)
  end

  defp make_delimited_case(vars, single_generated, %Field{type: :string} = field) do
    make_delimited_case_impl(vars, single_generated, field)
  end

  defp make_delimited_case(_vars, _single_generated, %Field{kind: %Scalar{}}) do
    []
  end

  defp make_delimited_case(_vars, _single_generated, %Field{kind: %OneOf{}}) do
    []
  end

  defp make_delimited_case(vars, single_generated, %Field{} = field) do
    make_delimited_case_impl(vars, single_generated, field)
  end

  defp make_delimited_case_impl(vars, single_generated, %Field{} = field) do
    # If the case to decode single occurrences of repeated elements has been generated,
    # it means that it's a repeated field of scalar elements (as non-scalar cannot be packed,
    # see https://developers.google.com/protocol-buffers/docs/encoding#optional).
    # Thus, it's useless to wrap in a list the result of the decoding as it means
    # we're using a parse_repeated_* function that always returns a list.
    update_field =
      if field.type == :bytes do
        make_update_field(vars.delimited, field, vars, _wrap_value = !single_generated)
      else
        # A generated single case means this delimited case decodes a packed run of
        # scalars: seed the parse_repeated_* accumulator with the field's current
        # (reversed) list so the run is prepended onto it directly.
        acc =
          if single_generated do
            quote(do: unquote(vars.msg).unquote(field.name))
          else
            quote(do: [])
          end

        parse_delimited = make_parse_delimited(vars.delimited, acc, field.type)
        make_update_field(parse_delimited, field, vars, _wrap_value = !single_generated)
      end

    key_bytes = make_literal_key_bytes(field.tag, :packed)

    # No one-byte-length fast clause here: its dynamic binary-size(len) segment
    # would defeat the shared match tree of the surrounding case, which measurably
    # blows up decoding of messages with many fields.
    quote do
      <<unquote(key_bytes), unquote(vars.bytes)::binary>> ->
        {len, unquote(vars.bytes)} = Protox.Varint.decode(unquote(vars.bytes))

        {unquote(vars.delimited), rest} = Protox.Decode.parse_delimited(unquote(vars.bytes), len)
        unquote(vars.msg) = unquote(update_field)
        parse_key_value(rest, unquote(vars.msg))
    end
  end

  defp make_update_field(value, %Field{kind: :map} = field, vars, _wrap_value) do
    quote do
      {entry_key, entry_value} = unquote(value)

      %{
        unquote(vars.msg)
        | unquote(field.name) => Map.put(unquote(vars.msg).unquote(field.name), entry_key, entry_value)
      }
    end
  end

  defp make_update_field(value, %Field{kind: %OneOf{}, type: {:message, _msg_type}} = field, vars, _wrap_value) do
    case field.label do
      :proto3_optional ->
        quote do
          # It's unclear if we should merge the value here or not. For now, conformance tests
          # pass without this.
          %{unquote(vars.msg) | unquote(field.name) => unquote(value)}
        end

      _other_label ->
        quote do
          case unquote(vars.msg).unquote(field.kind.parent) do
            {unquote(field.name), previous_value} ->
              %{
                unquote(vars.msg)
                | unquote(field.kind.parent) =>
                    {unquote(field.name), Protox.MergeMessage.merge(previous_value, unquote(value))}
              }

            _no_previous ->
              %{unquote(vars.msg) | unquote(field.kind.parent) => {unquote(field.name), unquote(value)}}
          end
        end
    end
  end

  defp make_update_field(value, %Field{kind: %OneOf{}} = field, vars, _wrap_value) do
    case field.label do
      :proto3_optional ->
        quote(do: %{unquote(vars.msg) | unquote(field.name) => unquote(value)})

      _other_label ->
        quote(do: %{unquote(vars.msg) | unquote(field.kind.parent) => {unquote(field.name), unquote(value)}})
    end
  end

  defp make_update_field(value, %Field{kind: %Scalar{}, type: {:message, _msg_type}} = field, vars, _wrap_value) do
    quote do
      %{
        unquote(vars.msg)
        | unquote(field.name) =>
            case unquote(vars.msg).unquote(field.name) do
              # The field is seen for the first time: nothing to merge.
              nil -> unquote(value)
              previous_value -> Protox.MergeMessage.merge(previous_value, unquote(value))
            end
      }
    end
  end

  defp make_update_field(value, %Field{kind: %Scalar{}} = field, vars, _wrap_value) do
    quote(do: %{unquote(vars.msg) | unquote(field.name) => unquote(value)})
  end

  defp make_update_field(value, %Field{kind: kind} = field, vars, wrap_value) when kind in [:packed, :unpacked] do
    # When wrap_value is false, value is a parse_repeated_* call already seeded
    # with the field's current list: it returns the full new (reversed)
    # accumulator, so it's stored as is.
    update_value =
      if wrap_value do
        quote(do: [unquote(value) | unquote(vars.msg).unquote(field.name)])
      else
        value
      end

    quote do
      %{unquote(vars.msg) | unquote(field.name) => unquote(update_value)}
    end
  end

  defp make_parse_delimited(bytes_var, _acc, :bytes) do
    quote(do: unquote(bytes_var))
  end

  defp make_parse_delimited(bytes_var, _acc, :string) do
    quote(do: Protox.Decode.validate_string!(unquote(bytes_var)))
  end

  defp make_parse_delimited(bytes_var, acc, {:enum, mod}) do
    quote(do: Protox.Decode.parse_repeated_enum(unquote(acc), unquote(bytes_var), unquote(mod)))
  end

  defp make_parse_delimited(bytes_var, _acc, {:message, mod}) do
    quote(do: unquote(mod).decode!(unquote(bytes_var)))
  end

  defp make_parse_delimited(bytes_var, acc, :bool) do
    quote(do: Protox.Decode.parse_repeated_bool(unquote(acc), unquote(bytes_var)))
  end

  defp make_parse_delimited(bytes_var, acc, :int32) do
    quote(do: Protox.Decode.parse_repeated_int32(unquote(acc), unquote(bytes_var)))
  end

  defp make_parse_delimited(bytes_var, acc, :uint32) do
    quote(do: Protox.Decode.parse_repeated_uint32(unquote(acc), unquote(bytes_var)))
  end

  defp make_parse_delimited(bytes_var, acc, :sint32) do
    quote(do: Protox.Decode.parse_repeated_sint32(unquote(acc), unquote(bytes_var)))
  end

  defp make_parse_delimited(bytes_var, acc, :int64) do
    quote(do: Protox.Decode.parse_repeated_int64(unquote(acc), unquote(bytes_var)))
  end

  defp make_parse_delimited(bytes_var, acc, :uint64) do
    quote(do: Protox.Decode.parse_repeated_uint64(unquote(acc), unquote(bytes_var)))
  end

  defp make_parse_delimited(bytes_var, acc, :sint64) do
    quote(do: Protox.Decode.parse_repeated_sint64(unquote(acc), unquote(bytes_var)))
  end

  defp make_parse_delimited(bytes_var, acc, :fixed32) do
    quote(do: Protox.Decode.parse_repeated_fixed32(unquote(acc), unquote(bytes_var)))
  end

  defp make_parse_delimited(bytes_var, acc, :fixed64) do
    quote(do: Protox.Decode.parse_repeated_fixed64(unquote(acc), unquote(bytes_var)))
  end

  defp make_parse_delimited(bytes_var, acc, :sfixed32) do
    quote(do: Protox.Decode.parse_repeated_sfixed32(unquote(acc), unquote(bytes_var)))
  end

  defp make_parse_delimited(bytes_var, acc, :sfixed64) do
    quote(do: Protox.Decode.parse_repeated_sfixed64(unquote(acc), unquote(bytes_var)))
  end

  defp make_parse_delimited(bytes_var, acc, :float) do
    quote(do: Protox.Decode.parse_repeated_float(unquote(acc), unquote(bytes_var)))
  end

  defp make_parse_delimited(bytes_var, acc, :double) do
    quote(do: Protox.Decode.parse_repeated_double(unquote(acc), unquote(bytes_var)))
  end

  defp make_parse_delimited(bytes_var, _acc, {key_type, value_type}) do
    unset_map_value =
      case value_type do
        {:message, msg_type} -> quote(do: struct(unquote(msg_type)))
        _scalar_type -> quote(do: Protox.Default.default(unquote(value_type)))
      end

    parser_fun_name = make_map_decode_fun_name(key_type, value_type)

    quote do
      {map_key, map_value} = unquote(parser_fun_name)({:unset, :unset}, unquote(bytes_var))

      resolved_map_key =
        case map_key do
          :unset -> Protox.Default.default(unquote(key_type))
          _already_set -> map_key
        end

      resolved_map_value =
        case map_value do
          :unset -> unquote(unset_map_value)
          _already_set -> map_value
        end

      {resolved_map_key, resolved_map_value}
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

      # The entry key and value always have tags 1 and 2: match their literal
      # wire keys rather than decoding them with Protox.Decode.parse_key/1.
      # As in parse_key_value/2, a known tag with an unexpected wire type falls
      # through to the unknown-field clause.
      entry_key_bytes = make_literal_key_bytes(1, key_type)
      entry_value_bytes = make_literal_key_bytes(2, value_type)

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
            case unquote(vars.bytes) do
              <<unquote(entry_key_bytes), unquote(vars.rest)::binary>> ->
                {res, unquote(vars.rest)} = unquote(key_parser)
                unquote(fun_name)({res, entry_value}, unquote(vars.rest))

              <<unquote(entry_value_bytes), unquote(vars.rest)::binary>> ->
                {res, unquote(vars.rest)} = unquote(value_parser)
                unquote(fun_name)({entry_key, res}, unquote(vars.rest))

              <<_unknown_entry_field::binary>> ->
                {tag, wire_type, unquote(vars.rest)} = Protox.Decode.parse_key(unquote(vars.bytes))

                {_unknown_value, unquote(vars.rest)} =
                  Protox.Decode.parse_unknown(tag, wire_type, unquote(vars.rest))

                unquote(fun_name)({entry_key, entry_value}, unquote(vars.rest))
            end
          end
        end

      {fun_name, code}
    end)
    |> Enum.sort(fn {lhs_fun_name, _lhs_code}, {rhs_fun_name, _rhs_code} -> lhs_fun_name < rhs_fun_name end)
    |> Enum.dedup_by(fn {fun_name, _code} -> fun_name end)
    |> Enum.map(fn {_fun_name, code} -> code end)
  end

  defp make_map_decode_fun_name(key_type, value_type) do
    value_name =
      case value_type do
        {:message, sub_msg} -> "msg_#{Atom.to_string(sub_msg)}"
        {:enum, enum} -> "enum_#{Atom.to_string(enum)}"
        ty -> "#{Atom.to_string(ty)}"
      end

    underscored_value_name =
      value_name
      |> Macro.underscore()
      |> String.replace("/", "_")

    String.to_atom("parse_#{Atom.to_string(key_type)}_#{underscored_value_name}")
  end

  defp make_parse_map_entry(vars, type) do
    parse_delimited =
      quote do
        {len, new_rest} = Protox.Varint.decode(unquote(vars.rest))
        {unquote(vars.delimited), delimited_rest} = Protox.Decode.parse_delimited(new_rest, len)

        {unquote(make_parse_delimited(vars.delimited, quote(do: []), type)), delimited_rest}
      end

    case type do
      :string -> parse_delimited
      :bytes -> parse_delimited
      {:message, _msg_type} -> parse_delimited
      _scalar_type -> make_parse_single(vars.rest, type)
    end
  end

  defp make_literal_key_bytes(tag, type) do
    tag
    |> Protox.Encode.make_key_bytes(type)
    |> elem(0)
    |> IO.iodata_to_binary()
  end
end
