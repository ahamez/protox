defmodule Protox.DefineEncoder do
  @moduledoc false
  # Internal. Generates the encoder of a message.

  use Protox.Float

  alias Protox.{Field, OneOf, Scalar}

  @spec define([Field.t()], :proto2 | :proto3, keyword()) :: Macro.t()
  def define(fields, syntax, opts \\ []) do
    vars = %{
      acc: Macro.var(:acc, __MODULE__),
      acc_size: Macro.var(:acc_size, __MODULE__),
      child_field_value: Macro.var(:child_field_value, __MODULE__),
      msg: Macro.var(:msg, __MODULE__)
    }

    required_fields = get_required_fields(fields)

    %{oneofs: oneofs, proto3_optionals: proto3_optionals, others: fields_without_oneofs} =
      Protox.Defs.split_oneofs(fields)

    # The diagnose function must replay fields in the same order encode_internal!/1
    # runs them, so that the first field to fail in the replay is the one that
    # failed originally.
    fields_in_encode_order = proto3_optionals ++ fields_without_oneofs

    top_level_encode_fun = make_top_level_encode_fun(oneofs, fields_in_encode_order)

    encode_oneof_funs = make_encode_oneof_funs(oneofs, syntax, vars)
    encode_field_funs = make_encode_field_funs(fields, required_fields, syntax, vars)
    encode_diagnose_fun = make_encode_diagnose_fun(oneofs, fields_in_encode_order, vars)
    encode_unknown_fields_fun = make_encode_unknown_fields_fun(vars, opts)

    quote do
      unquote(top_level_encode_fun)
      unquote_splicing(encode_oneof_funs)
      unquote_splicing(encode_field_funs)
      unquote(encode_diagnose_fun)
      unquote(encode_unknown_fields_fun)
    end
  end

  defp make_top_level_encode_fun(oneofs, fields) do
    initial_acc = quote(do: {[], 0})

    initial_acc
    |> make_encode_oneof_fun(oneofs)
    |> make_encode_fun_field(fields)
    |> make_encode_fun_body()
  end

  defp make_encode_fun_body(ast) do
    quote do
      @spec encode(t()) :: {:ok, iodata(), non_neg_integer()} | {:error, any()}
      def encode(msg) do
        msg
        |> encode!()
        |> Tuple.insert_at(0, :ok)
      rescue
        e in [Protox.EncodingError, Protox.RequiredFieldsError] ->
          {:error, e}
      end

      @spec encode!(t()) :: {iodata(), non_neg_integer()} | no_return()
      def encode!(msg) do
        encode_internal!(msg)
      rescue
        e in [Protox.EncodingError, Protox.RequiredFieldsError] ->
          reraise e, __STACKTRACE__

        e ->
          # Cold path: re-run each field encoder in isolation to attribute the
          # error to the faulty field. Reraises the original error when the
          # diagnosis doesn't find an attributable field.
          encode_diagnose!(msg)
          reraise e, __STACKTRACE__
      end

      @doc false
      def encode_internal!(msg), do: unquote(ast)
    end
  end

  defp make_encode_fun_field(ast, fields) do
    ast =
      Enum.reduce(fields, ast, fn %Protox.Field{} = field, ast_acc ->
        pipe(ast_acc, quote(do: unquote(make_encode_field_fun_name(field.name))(msg)))
      end)

    pipe(ast, quote(do: encode_unknown_fields(msg)))
  end

  defp make_encode_oneof_fun(ast, oneofs) do
    Enum.reduce(oneofs, ast, fn {parent_name, _children}, ast_acc ->
      pipe(ast_acc, quote(do: unquote(make_encode_field_fun_name(parent_name))(msg)))
    end)
  end

  # Emits `lhs |> call` so the generated chain reads as a pipeline. Built as a
  # raw AST node: a literal single-step |> in a quote would be collapsed back
  # to a nested call by the Quokka style pass of mix format.
  defp pipe(lhs, call_ast), do: {:|>, [], [lhs, call_ast]}

  defp make_encode_oneof_funs(oneofs, syntax, vars) do
    for {parent_name, children} <- oneofs do
      nil_clause =
        quote do
          nil -> {unquote(vars.acc), unquote(vars.acc_size)}
        end

      children_clauses_ast =
        Enum.flat_map(children, fn %Field{} = child_field ->
          encode_child_body = make_encode_field_body(child_field, false, syntax, vars)

          quote do
            {unquote(child_field.name), unquote(vars.child_field_value)} ->
              unquote(encode_child_body)
          end
        end)

      quote do
        defp unquote(make_encode_field_fun_name(parent_name))(
               {unquote(vars.acc), unquote(vars.acc_size)},
               msg
             ) do
          case :erlang.map_get(unquote(parent_name), msg) do
            unquote(nil_clause ++ children_clauses_ast)
          end
        end
      end
    end
  end

  defp make_encode_field_funs(fields, required_fields, syntax, vars) do
    fields =
      Enum.reject(fields, fn
        %Field{label: :proto3_optional, kind: %OneOf{}} -> false
        %Field{kind: %OneOf{}} -> true
        _other_field -> false
      end)

    for %Field{name: name} = field <- fields do
      required = name in required_fields
      fun_name = make_encode_field_fun_name(name)
      fun_ast = make_encode_field_body(field, required, syntax, vars)

      quote do
        defp unquote(fun_name)({unquote(vars.acc), unquote(vars.acc_size)}, unquote(vars.msg)) do
          unquote(fun_ast)
        end
      end
    end
  end

  # Cold path, called only after an encoding error: hands the field encoders
  # and the message-children modules to Protox.Encode.find_invalid_field!/2,
  # in encoding order (oneofs first), so the error is attributed to the field
  # that failed originally.
  defp make_encode_diagnose_fun(oneofs, fields, vars) do
    oneof_entries =
      Enum.map(oneofs, fn {parent_name, children} ->
        message_children = for %Field{name: name, type: {:message, mod}} <- children, do: {name, mod}

        quote do
          {:oneof, unquote(parent_name), unquote(make_local_capture(parent_name)), unquote(message_children)}
        end
      end)

    field_entries =
      Enum.map(fields, fn %Field{name: name} = field ->
        quote do
          {unquote(name), unquote(make_local_capture(name)), unquote(message_child_module(field))}
        end
      end)

    entries = oneof_entries ++ field_entries

    if entries == [] do
      quote do
        defp encode_diagnose!(_msg), do: :ok
      end
    else
      quote do
        defp encode_diagnose!(%{__struct__: __MODULE__} = unquote(vars.msg)) do
          Protox.Encode.find_invalid_field!(unquote(vars.msg), unquote(entries))
        end

        # Not a valid input for this message: no field can be blamed, let the
        # caller reraise the original error.
        defp encode_diagnose!(_malformed_input), do: :ok
      end
    end
  end

  # AST of `&encode_<name>/2`.
  defp make_local_capture(name) do
    fun_name = make_encode_field_fun_name(name)
    {:&, [], [{:/, [], [{fun_name, [], __MODULE__}, 2]}]}
  end

  # The module of a field's message children (single, repeated or map values),
  # or nil if the field cannot hold messages.
  defp message_child_module(%Field{type: {:message, sub_msg}}), do: sub_msg
  defp message_child_module(%Field{type: {_key_type, {:message, sub_msg}}}), do: sub_msg
  defp message_child_module(_field), do: nil

  defp make_encode_field_body(%Field{kind: %Scalar{}} = field, required, syntax, vars) do
    {key, key_size} = Protox.Encode.make_key_bytes(field.tag, field.type)
    var = field_value(vars.msg, field.name)
    encode_value_clause = make_encode_value_clause(field.type, var, key, key_size, vars)

    case {syntax, required} do
      {:proto2, true = _required} ->
        quote do
          case unquote(var) do
            nil -> raise Protox.RequiredFieldsError.new([unquote(field.name)])
            _value -> unquote(encode_value_clause)
          end
        end

      {:proto2, false = _required} ->
        quote do
          case unquote(var) do
            nil -> {unquote(vars.acc), unquote(vars.acc_size)}
            _value -> unquote(encode_value_clause)
          end
        end

      {:proto3, _required} ->
        quote do
          # Use == rather than pattern match for float comparison
          if unquote(var) == unquote(field.kind.default_value) do
            {unquote(vars.acc), unquote(vars.acc_size)}
          else
            unquote(encode_value_clause)
          end
        end
    end
  end

  defp make_encode_field_body(%Field{label: :proto3_optional, kind: %OneOf{}} = field, _required, _syntax, vars) do
    {key, key_size} = Protox.Encode.make_key_bytes(field.tag, field.type)
    var = Macro.var(:child_field_value, __MODULE__)
    encode_value_clause = make_encode_value_clause(field.type, var, key, key_size, vars)

    quote do
      case unquote(field_value(vars.msg, field.name)) do
        nil ->
          {unquote(vars.acc), unquote(vars.acc_size)}

        unquote(var) ->
          unquote(encode_value_clause)
      end
    end
  end

  defp make_encode_field_body(%Field{kind: %OneOf{}} = field, _required, _syntax, vars) do
    {key, key_size} = Protox.Encode.make_key_bytes(field.tag, field.type)

    # The dispatch on the correct child is performed by the parent encoding function,
    # this is why we don't check if the child is set.
    make_encode_value_clause(field.type, vars.child_field_value, key, key_size, vars)
  end

  defp make_encode_field_body(%Field{kind: :packed} = field, _required, _syntax, vars) do
    {key_bytes, key_size} = Protox.Encode.make_key_bytes(field.tag, :packed)
    encode_packed_ast = make_encode_packed_body(field.type)

    quote do
      case unquote(field_value(vars.msg, field.name)) do
        [] ->
          {unquote(vars.acc), unquote(vars.acc_size)}

        values ->
          value_bytes = unquote(encode_packed_ast)
          value_size = byte_size(value_bytes)
          value_size_bytes = Protox.Varint.encode(value_size)

          {
            [unquote(key_bytes), value_size_bytes, value_bytes | unquote(vars.acc)],
            unquote(vars.acc_size) + unquote(key_size) + value_size + byte_size(value_size_bytes)
          }
      end
    end
  end

  defp make_encode_field_body(%Field{kind: :unpacked} = field, _required, _syntax, vars) do
    encode_repeated_ast = make_encode_repeated_body(field.tag, field.type)

    quote do
      case unquote(field_value(vars.msg, field.name)) do
        [] ->
          {unquote(vars.acc), unquote(vars.acc_size)}

        values ->
          {value_bytes, value_size} = unquote(encode_repeated_ast)
          {[value_bytes | unquote(vars.acc)], unquote(vars.acc_size) + value_size}
      end
    end
  end

  defp make_encode_field_body(%Field{kind: :map} = field, _required, _syntax, vars) do
    # Each key/value entry of a map has the same layout as a message.
    # https://developers.google.com/protocol-buffers/docs/proto3#backwards-compatibility

    {field_key, field_key_size} = Protox.Encode.make_key_bytes(field.tag, :map_entry)

    {map_key_type, map_value_type} = field.type

    k_var = Macro.var(:k, __MODULE__)
    v_var = Macro.var(:v, __MODULE__)

    encode_map_key_binding =
      make_encode_value_binding(
        map_key_type,
        k_var,
        Macro.var(:k_value_bytes, __MODULE__),
        Macro.var(:k_value_len, __MODULE__)
      )

    encode_map_value_binding =
      make_encode_value_binding(
        map_value_type,
        v_var,
        Macro.var(:v_value_bytes, __MODULE__),
        Macro.var(:v_value_len, __MODULE__)
      )

    {k_key_bytes, k_key_size} = Protox.Encode.make_key_bytes(1, map_key_type)
    {v_key_bytes, v_key_size} = Protox.Encode.make_key_bytes(2, map_value_type)
    keys_len = k_key_size + v_key_size

    quote do
      map = unquote(field_value(vars.msg, field.name))

      if map_size(map) == 0 do
        {unquote(vars.acc), unquote(vars.acc_size)}
      else
        :maps.fold(
          fn unquote(k_var), unquote(v_var), {unquote(vars.acc), unquote(vars.acc_size)} ->
            unquote(encode_map_key_binding)
            unquote(encode_map_value_binding)

            len = unquote(keys_len) + k_value_len + v_value_len
            len_varint = Protox.Varint.encode(len)

            unquote(vars.acc) = [
              <<unquote(field_key), len_varint::binary, unquote(k_key_bytes)>>,
              k_value_bytes,
              unquote(v_key_bytes),
              v_value_bytes
              | unquote(vars.acc)
            ]

            {
              unquote(vars.acc),
              unquote(vars.acc_size) + unquote(field_key_size + keys_len) + k_value_len +
                v_value_len + byte_size(len_varint)
            }
          end,
          {unquote(vars.acc), unquote(vars.acc_size)},
          map
        )
      end
    end
  end

  # Shared fragment: prepend the field's key and encoded bytes to the accumulator, updating its
  # size. The bytes come back as a *list* of items to splice, because a length-delimited field
  # contributes two -- its prefix and its payload -- and consing them straight onto the
  # accumulator is free, where wrapping them in their own list was not.
  defp make_encode_value_clause(type, value_var, key, key_size, vars) do
    {prelude, bytes_items, size_ast} = get_encode_value_parts(type, value_var)

    quote do
      unquote_splicing(prelude)

      {
        [unquote(key), unquote_splicing(bytes_items) | unquote(vars.acc)],
        unquote(vars.acc_size) + unquote(key_size) + unquote(size_ast)
      }
    end
  end

  # The map entry and repeated encoders need the bytes as a single term, so a multi-item field
  # is re-wrapped into a list for them. Only the scalar field path gets the flat splice.
  defp make_encode_value_binding(type, value_var, bytes_var, size_var) do
    {prelude, bytes_items, size_ast} = get_encode_value_parts(type, value_var)

    bytes_ast =
      case bytes_items do
        [single] -> single
        several -> quote(do: [unquote_splicing(several)])
      end

    quote do
      unquote_splicing(prelude)
      unquote(bytes_var) = unquote(bytes_ast)
      unquote(size_var) = unquote(size_ast)
    end
  end

  defp make_encode_unknown_fields_fun(_vars, opts) do
    unknown_fields_name = Keyword.fetch!(opts, :unknown_fields_name)

    quote do
      defp encode_unknown_fields(acc, msg) do
        Protox.Encode.encode_unknown_fields(acc, :erlang.map_get(unquote(unknown_fields_name), msg))
      end
    end
  end

  @packed_binary_appenders %{
    fixed32: :encode_packed_fixed32,
    fixed64: :encode_packed_fixed64,
    # The signed modifier is a no-op in binary construction.
    sfixed32: :encode_packed_fixed32,
    sfixed64: :encode_packed_fixed64,
    float: :encode_packed_float,
    double: :encode_packed_double,
    int32: :encode_packed_int32,
    int64: :encode_packed_int64,
    # uint32/64 encode like their signed counterparts: out-of-range values
    # are truncated the same way.
    uint32: :encode_packed_int32,
    uint64: :encode_packed_int64,
    # Zigzag encoding is width-agnostic.
    sint32: :encode_packed_sint,
    sint64: :encode_packed_sint,
    bool: :encode_packed_bool
  }

  # Packed elements are appended to a single contiguous binary instead of one
  # binary and one iodata cell per element, with the packed length derived
  # from byte_size/1 by Protox.Encode.prepend_packed/5.
  defp make_encode_packed_body({:enum, mod}) do
    quote(do: Protox.Encode.encode_packed_enum(values, <<>>, &unquote(mod).encode/1))
  end

  defp make_encode_packed_body(type) do
    appender = Map.fetch!(@packed_binary_appenders, type)

    quote(do: Protox.Encode.unquote(appender)(values, <<>>))
  end

  defp make_encode_repeated_body(tag, type) do
    {key_bytes, key_bytes_sz} = Protox.Encode.make_key_bytes(tag, type)
    value_var = Macro.var(:value, __MODULE__)

    encode_value_binding =
      make_encode_value_binding(
        type,
        value_var,
        Macro.var(:value_bytes, __MODULE__),
        Macro.var(:value_bytes_size, __MODULE__)
      )

    quote do
      Enum.reduce(
        values,
        {_local_acc = [], _local_acc_size = 0},
        fn unquote(value_var), {local_acc, local_acc_size} ->
          unquote(encode_value_binding)

          {
            [local_acc, unquote(key_bytes), value_bytes],
            local_acc_size + unquote(key_bytes_sz) + value_bytes_size
          }
        end
      )
    end
  end

  # Returns `{prelude, bytes_items, size_ast}` for a value of `type`:
  #
  #   * `prelude` binds whatever the other two need,
  #   * `bytes_items` is the list of terms to splice onto the accumulator,
  #   * `size_ast` evaluates to their total byte count.
  #
  # Keeping the size a separate expression rather than a returned tuple element is what stops
  # the size from costing an allocation: a fixed-width type knows it at generation time, a
  # varint gets it from byte_size/1 for free, and the rest bind it in their prelude.

  # The child module is known at generation time: dispatch on it statically and
  # use its rescue-free encoding path. The match on __struct__ rejects any
  # other value with a MatchError, which the diagnosis attributes: without it,
  # a wrong-typed struct or a plain map with matching field names would be
  # silently encoded under this message's tags. A %unquote(msg_type){} pattern
  # is not usable here, as the child module may not be compiled yet.
  defp get_encode_value_parts({:message, msg_type}, value_var) do
    prelude =
      quote do
        %{__struct__: unquote(msg_type)} = child = unquote(value_var)
        {child_bytes, child_size} = unquote(msg_type).encode_internal!(child)
        child_size_bytes = Protox.Varint.encode(child_size)
      end

    {[prelude], [quote(do: child_size_bytes), quote(do: child_bytes)],
     quote(do: byte_size(child_size_bytes) + child_size)}
  end

  defp get_encode_value_parts({:enum, enum}, value_var) do
    make_inline_int32_parts(quote(do: unquote(enum).encode(unquote(value_var))))
  end

  defp get_encode_value_parts(:bool, value_var) do
    {[], [quote(do: Protox.Encode.encode_bool(unquote(value_var)))], 1}
  end

  # A length-delimited field splices its prefix and its payload separately: wrapping them in a
  # list of their own, as returning `{iodata, size}` from a helper forced, cost 7 words a field.
  defp get_encode_value_parts(:string, value_var) do
    prelude =
      quote do
        delimited = unquote(value_var)
        delimited_prefix = Protox.Encode.encode_string_prefix(delimited)
      end

    {[prelude], [quote(do: delimited_prefix), quote(do: delimited)],
     quote(do: byte_size(delimited_prefix) + byte_size(delimited))}
  end

  defp get_encode_value_parts(:bytes, value_var) do
    prelude =
      quote do
        delimited = unquote(value_var)
        delimited_prefix = Protox.Varint.encode(byte_size(delimited))
      end

    {[prelude], [quote(do: delimited_prefix), quote(do: delimited)],
     quote(do: byte_size(delimited_prefix) + byte_size(delimited))}
  end

  # Varint scalars are inlined in the generated code: the truncation is a
  # couple of integer instructions, and going through the Protox.Encode
  # helpers would cost two remote calls per field.

  defp get_encode_value_parts(type, value_var) when type in [:int32, :uint32] do
    make_inline_int32_parts(value_var)
  end

  defp get_encode_value_parts(type, value_var) when type in [:int64, :uint64] do
    prelude =
      quote do
        value_bytes = Protox.Varint.encode(:erlang.band(unquote(value_var), 0xFFFF_FFFF_FFFF_FFFF))
      end

    {[prelude], [quote(do: value_bytes)], quote(do: byte_size(value_bytes))}
  end

  defp get_encode_value_parts(type, value_var) when type in [:sint32, :sint64] do
    prelude = quote(do: value_bytes = Protox.Varint.encode(Protox.Zigzag.encode(unquote(value_var))))

    {[prelude], [quote(do: value_bytes)], quote(do: byte_size(value_bytes))}
  end

  defp get_encode_value_parts(:fixed32, value_var) do
    {[], [quote(do: <<unquote(value_var)::little-32>>)], 4}
  end

  defp get_encode_value_parts(:fixed64, value_var) do
    {[], [quote(do: <<unquote(value_var)::little-64>>)], 8}
  end

  defp get_encode_value_parts(:sfixed32, value_var) do
    {[], [quote(do: <<unquote(value_var)::signed-little-32>>)], 4}
  end

  defp get_encode_value_parts(:sfixed64, value_var) do
    {[], [quote(do: <<unquote(value_var)::signed-little-64>>)], 8}
  end

  defp get_encode_value_parts(:float, value_var) do
    bytes =
      quote do
        case unquote(value_var) do
          :infinity -> unquote(@positive_infinity_32)
          :"-infinity" -> unquote(@negative_infinity_32)
          :nan -> unquote(@nan_32)
          value -> <<value::float-little-32>>
        end
      end

    {[], [bytes], 4}
  end

  defp get_encode_value_parts(:double, value_var) do
    bytes =
      quote do
        case unquote(value_var) do
          :infinity -> unquote(@positive_infinity_64)
          :"-infinity" -> unquote(@negative_infinity_64)
          :nan -> unquote(@nan_64)
          value -> <<value::float-little-64>>
        end
      end

    {[], [bytes], 8}
  end

  # A negative int32 scalar is encoded as its 64-bit two's complement (ten
  # bytes on the wire). Note a non-integer value passes the >= 0 comparison
  # (term order) and raises from the truncation, which the diagnosis
  # attributes.
  defp make_inline_int32_parts(value_ast) do
    prelude =
      quote do
        value = unquote(value_ast)

        value_bytes =
          if value >= 0 do
            Protox.Varint.encode(:erlang.band(value, 0xFFFF_FFFF))
          else
            Protox.Varint.encode(:erlang.band(value, 0xFFFF_FFFF_FFFF_FFFF))
          end
      end

    {[prelude], [quote(do: value_bytes)], quote(do: byte_size(value_bytes))}
  end

  # `msg.field` compiles to a map match *plus* a fallback arm that calls
  # elixir_erl_pass:no_parens_remote/2 in case `msg` turns out to be a module, so the access is
  # never a single get_map_element and the compiler cannot pin the type of `msg`. The field is
  # always present -- it is a struct key -- so :erlang.map_get/2 is the same lookup without the
  # dead branch.
  defp field_value(msg_var, field_name) do
    quote(do: :erlang.map_get(unquote(field_name), unquote(msg_var)))
  end

  defp make_encode_field_fun_name(field) when is_atom(field) do
    String.to_atom("encode_#{field}")
  end

  defp get_required_fields(fields) do
    for %Field{label: :required, name: name} <- fields, do: name
  end
end
