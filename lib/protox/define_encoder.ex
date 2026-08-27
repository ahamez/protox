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
          case msg.unquote(parent_name) do
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
    var = quote do: unquote(vars.msg).unquote(field.name)
    encode_value_ast = get_encode_value_body(field.type, var)
    encode_value_clause = make_encode_value_clause(encode_value_ast, key, key_size, vars)

    case {syntax, required} do
      {:proto2, true = _required} ->
        quote do
          case unquote(vars.msg).unquote(field.name) do
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
    encode_value_ast = get_encode_value_body(field.type, var)
    encode_value_clause = make_encode_value_clause(encode_value_ast, key, key_size, vars)

    quote do
      case unquote(vars.msg).unquote(field.name) do
        nil ->
          {unquote(vars.acc), unquote(vars.acc_size)}

        unquote(var) ->
          unquote(encode_value_clause)
      end
    end
  end

  defp make_encode_field_body(%Field{kind: %OneOf{}} = field, _required, _syntax, vars) do
    {key, key_size} = Protox.Encode.make_key_bytes(field.tag, field.type)
    encode_value_ast = get_encode_value_body(field.type, vars.child_field_value)

    # The dispatch on the correct child is performed by the parent encoding function,
    # this is why we don't check if the child is set.
    make_encode_value_clause(encode_value_ast, key, key_size, vars)
  end

  # Shared fragment: decode `encode_value_ast` into `value_bytes`/`value_bytes_size`, then
  # prepend the field's key and value bytes to the accumulator, updating its size.
  defp make_encode_value_clause(encode_value_ast, key, key_size, vars) do
    quote do
      {value_bytes, value_bytes_size} = unquote(encode_value_ast)

      {
        [unquote(key), value_bytes | unquote(vars.acc)],
        unquote(vars.acc_size) + unquote(key_size) + value_bytes_size
      }
    end
  end

  defp make_encode_field_body(%Field{kind: :packed} = field, _required, _syntax, vars) do
    {key_bytes, key_size} = Protox.Encode.make_key_bytes(field.tag, :packed)
    encode_packed_ast = make_encode_packed_body(field.type)

    quote do
      case unquote(vars.msg).unquote(field.name) do
        [] ->
          {unquote(vars.acc), unquote(vars.acc_size)}

        values ->
          value_bytes = unquote(encode_packed_ast)
          value_size = byte_size(value_bytes)
          {value_size_bytes, value_size_size} = Protox.Varint.encode(value_size)

          {
            [unquote(key_bytes), value_size_bytes, value_bytes | unquote(vars.acc)],
            unquote(vars.acc_size) + unquote(key_size) + value_size + value_size_size
          }
      end
    end
  end

  defp make_encode_field_body(%Field{kind: :unpacked} = field, _required, _syntax, vars) do
    encode_repeated_ast = make_encode_repeated_body(field.tag, field.type)

    quote do
      case unquote(vars.msg).unquote(field.name) do
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

    encode_map_key_ast = get_encode_value_body(map_key_type, k_var)
    encode_map_value_ast = get_encode_value_body(map_value_type, v_var)

    {k_key_bytes, k_key_size} = Protox.Encode.make_key_bytes(1, map_key_type)
    {v_key_bytes, v_key_size} = Protox.Encode.make_key_bytes(2, map_value_type)
    keys_len = k_key_size + v_key_size

    quote do
      map = Map.fetch!(unquote(vars.msg), unquote(field.name))

      if map_size(map) == 0 do
        {unquote(vars.acc), unquote(vars.acc_size)}
      else
        :maps.fold(
          fn unquote(k_var), unquote(v_var), {unquote(vars.acc), unquote(vars.acc_size)} ->
            {k_value_bytes, k_value_len} = unquote(encode_map_key_ast)
            {v_value_bytes, v_value_len} = unquote(encode_map_value_ast)

            len = unquote(keys_len) + k_value_len + v_value_len
            {len_varint, len_varint_size} = Protox.Varint.encode(len)

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
                v_value_len + len_varint_size
            }
          end,
          {unquote(vars.acc), unquote(vars.acc_size)},
          map
        )
      end
    end
  end

  defp make_encode_unknown_fields_fun(_vars, opts) do
    unknown_fields_name = Keyword.fetch!(opts, :unknown_fields_name)

    quote do
      defp encode_unknown_fields(acc, msg) do
        Protox.Encode.encode_unknown_fields(acc, msg.unquote(unknown_fields_name))
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
    encode_value_ast = get_encode_value_body(type, value_var)

    quote do
      Enum.reduce(
        values,
        {_local_acc = [], _local_acc_size = 0},
        fn unquote(value_var), {local_acc, local_acc_size} ->
          {value_bytes, value_bytes_size} = unquote(encode_value_ast)

          {
            [local_acc, unquote(key_bytes), value_bytes],
            local_acc_size + unquote(key_bytes_sz) + value_bytes_size
          }
        end
      )
    end
  end

  # The child module is known at generation time: dispatch on it statically and
  # use its rescue-free encoding path. The match on __struct__ rejects any
  # other value with a MatchError, which the diagnosis attributes: without it,
  # a wrong-typed struct or a plain map with matching field names would be
  # silently encoded under this message's tags. A %unquote(msg_type){} pattern
  # is not usable here, as the child module may not be compiled yet.
  defp get_encode_value_body({:message, msg_type}, value_var) do
    quote do
      %{__struct__: unquote(msg_type)} = child = unquote(value_var)
      {child_bytes, child_size} = unquote(msg_type).encode_internal!(child)
      {child_size_bytes, child_size_bytes_size} = Protox.Varint.encode(child_size)
      {[child_size_bytes, child_bytes], child_size + child_size_bytes_size}
    end
  end

  defp get_encode_value_body({:enum, enum}, value_var) do
    make_inline_int32_body(quote(do: unquote(enum).encode(unquote(value_var))))
  end

  defp get_encode_value_body(:bool, value_var) do
    quote(do: Protox.Encode.encode_bool(unquote(value_var)))
  end

  defp get_encode_value_body(:bytes, value_var) do
    quote(do: Protox.Encode.encode_bytes(unquote(value_var)))
  end

  defp get_encode_value_body(:string, value_var) do
    quote(do: Protox.Encode.encode_string(unquote(value_var)))
  end

  # Varint scalars are inlined in the generated code: the truncation is a
  # couple of integer instructions, and going through the Protox.Encode
  # helpers would cost two remote calls per field.

  defp get_encode_value_body(:int32, value_var), do: make_inline_int32_body(value_var)
  defp get_encode_value_body(:uint32, value_var), do: make_inline_int32_body(value_var)

  defp get_encode_value_body(type, value_var) when type in [:int64, :uint64] do
    quote do
      Protox.Varint.encode(:erlang.band(unquote(value_var), 0xFFFF_FFFF_FFFF_FFFF))
    end
  end

  defp get_encode_value_body(type, value_var) when type in [:sint32, :sint64] do
    quote do
      Protox.Varint.encode(Protox.Zigzag.encode(unquote(value_var)))
    end
  end

  defp get_encode_value_body(:fixed32, value_var) do
    quote(do: {<<unquote(value_var)::little-32>>, 4})
  end

  defp get_encode_value_body(:fixed64, value_var) do
    quote(do: {<<unquote(value_var)::little-64>>, 8})
  end

  defp get_encode_value_body(:sfixed32, value_var) do
    quote(do: {<<unquote(value_var)::signed-little-32>>, 4})
  end

  defp get_encode_value_body(:sfixed64, value_var) do
    quote(do: {<<unquote(value_var)::signed-little-64>>, 8})
  end

  defp get_encode_value_body(:float, value_var) do
    quote do
      case unquote(value_var) do
        :infinity -> {unquote(@positive_infinity_32), 4}
        :"-infinity" -> {unquote(@negative_infinity_32), 4}
        :nan -> {unquote(@nan_32), 4}
        value -> {<<value::float-little-32>>, 4}
      end
    end
  end

  defp get_encode_value_body(:double, value_var) do
    quote do
      case unquote(value_var) do
        :infinity -> {unquote(@positive_infinity_64), 8}
        :"-infinity" -> {unquote(@negative_infinity_64), 8}
        :nan -> {unquote(@nan_64), 8}
        value -> {<<value::float-little-64>>, 8}
      end
    end
  end

  # A negative int32 scalar is encoded as its 64-bit two's complement (ten
  # bytes on the wire). Note a non-integer value passes the >= 0 comparison
  # (term order) and raises from the truncation, which the diagnosis
  # attributes.
  defp make_inline_int32_body(value_ast) do
    quote do
      value = unquote(value_ast)

      if value >= 0 do
        Protox.Varint.encode(:erlang.band(value, 0xFFFF_FFFF))
      else
        Protox.Varint.encode(:erlang.band(value, 0xFFFF_FFFF_FFFF_FFFF))
      end
    end
  end

  defp make_encode_field_fun_name(field) when is_atom(field) do
    String.to_atom("encode_#{field}")
  end

  defp get_required_fields(fields) do
    for %Field{label: :required, name: name} <- fields, do: name
  end
end
