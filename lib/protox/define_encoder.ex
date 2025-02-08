defmodule Protox.DefineEncoder do
  @moduledoc false
  # Internal. Generates the encoder of a message.

  alias Protox.{Field, OneOf, Scalar}

  def define(fields, syntax, opts \\ []) do
    vars = %{
      acc: Macro.var(:acc, __MODULE__),
      acc_size: Macro.var(:acc_size, __MODULE__),
      msg: Macro.var(:msg, __MODULE__)
    }

    required_fields = get_required_fields(fields)

    %{oneofs: oneofs, proto3_optionals: proto3_optionals, others: fields_without_oneofs} =
      Protox.Defs.split_oneofs(fields)

    top_level_encode_fun =
      make_top_level_encode_fun(oneofs, proto3_optionals ++ fields_without_oneofs)

    encode_oneof_funs = make_encode_oneof_funs(oneofs)
    encode_field_funs = make_encode_field_funs(fields, required_fields, syntax, vars)
    encode_unknown_fields_fun = make_encode_unknown_fields_fun(vars, opts)

    quote do
      _generator = unquote(make_generator(__ENV__))
      unquote(top_level_encode_fun)
      unquote_splicing(encode_oneof_funs)
      unquote_splicing(encode_field_funs)
      unquote(encode_unknown_fields_fun)
    end
  end

  defp make_top_level_encode_fun(oneofs, fields) do
    quote(do: {_acc = [], _acc_size = 0})
    |> make_encode_oneof_fun(oneofs)
    |> make_encode_fun_field(fields)
    |> make_encode_fun_body()
  end

  defp make_encode_fun_body(ast) do
    quote do
      @spec encode(t()) :: {:ok, iodata(), non_neg_integer()} | {:error, any()}
      def encode(msg) do
        _generator = unquote(make_generator(__ENV__))

        try do
          msg |> encode!() |> Tuple.insert_at(0, :ok)
        rescue
          e in [Protox.EncodingError, Protox.RequiredFieldsError] ->
            {:error, e}
        end
      end

      @spec encode!(t()) :: {iodata(), non_neg_integer()} | no_return()
      def encode!(msg), do: unquote(ast)
    end
  end

  defp make_encode_fun_field(ast, fields) do
    ast =
      Enum.reduce(fields, ast, fn %Protox.Field{} = field, ast_acc ->
        quote do
          unquote(ast_acc)
          |> unquote(make_encode_field_fun_name(field.name))(msg)
        end
      end)

    quote do
      unquote(ast) |> encode_unknown_fields(msg)
    end
  end

  defp make_encode_oneof_fun(ast, oneofs) do
    Enum.reduce(oneofs, ast, fn {parent_name, _children}, ast_acc ->
      quote do
        unquote(ast_acc)
        |> unquote(make_encode_field_fun_name(parent_name))(msg)
      end
    end)
  end

  defp make_encode_oneof_funs(oneofs) do
    for {parent_name, children} <- oneofs do
      nil_clause =
        quote do
          nil -> acc
        end

      children_clauses_ast =
        Enum.flat_map(children, fn %Field{} = child_field ->
          encode_child_fun_name = make_encode_field_fun_name(child_field.name)

          quote do
            {unquote(child_field.name), _field_value} -> unquote(encode_child_fun_name)(acc, msg)
          end
        end)

      quote do
        defp unquote(make_encode_field_fun_name(parent_name))(acc, msg) do
          case msg.unquote(parent_name) do
            unquote(nil_clause ++ children_clauses_ast)
          end
        end
      end
    end
  end

  defp make_encode_field_funs(fields, required_fields, syntax, vars) do
    for %Field{name: name} = field <- fields do
      required = name in required_fields
      fun_name = make_encode_field_fun_name(name)
      fun_ast = make_encode_field_body(field, required, syntax, vars)

      quote do
        defp unquote(fun_name)({unquote(vars.acc), unquote(vars.acc_size)}, unquote(vars.msg)) do
          try do
            unquote(fun_ast)
          rescue
            ArgumentError ->
              reraise Protox.EncodingError.new(unquote(name), "invalid field value"),
                      __STACKTRACE__
          end
        end
      end
    end
  end

  defp make_encode_field_body(%Field{kind: %Scalar{}} = field, required, syntax, vars) do
    {key, key_size} = Protox.Encode.make_key_bytes(field.tag, field.type)
    var = quote do: unquote(vars.msg).unquote(field.name)
    encode_value_ast = get_encode_value_body(field.type, var)

    encode_value_clause =
      quote do
        {value_bytes, value_bytes_size} = unquote(encode_value_ast)

        {
          [unquote(key), value_bytes | unquote(vars.acc)],
          unquote(vars.acc_size) + unquote(key_size) + value_bytes_size
        }
      end

    case {syntax, required} do
      {:proto2, _required = true} ->
        quote do
          case unquote(vars.msg).unquote(field.name) do
            nil -> raise Protox.RequiredFieldsError.new([unquote(field.name)])
            _ -> unquote(encode_value_clause)
          end
        end

      {:proto2, _required = false} ->
        quote do
          case unquote(var) do
            nil -> {unquote(vars.acc), unquote(vars.acc_size)}
            _ -> unquote(encode_value_clause)
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

  # Generate the AST to encode child `field.name` of a oneof
  defp make_encode_field_body(
         %Field{kind: %OneOf{}} = field,
         _required,
         _syntax,
         vars
       ) do
    {key, key_size} = Protox.Encode.make_key_bytes(field.tag, field.type)
    var = Macro.var(:child_field_value, __MODULE__)
    encode_value_ast = get_encode_value_body(field.type, var)

    case field.label do
      :proto3_optional ->
        quote do
          case unquote(vars.msg).unquote(field.name) do
            nil ->
              {unquote(vars.acc), unquote(vars.acc_size)}

            unquote(var) ->
              {value_bytes, value_bytes_size} = unquote(encode_value_ast)

              {
                [unquote(key), value_bytes | unquote(vars.acc)],
                unquote(vars.acc_size) + unquote(key_size) + value_bytes_size
              }
          end
        end

      _ ->
        # The dispatch on the correct child is performed by the parent encoding function,
        # this is why we don't check if the child is set.
        quote do
          {_, unquote(var)} = unquote(vars.msg).unquote(field.kind.parent)
          {value_bytes, value_bytes_size} = unquote(encode_value_ast)

          {
            [unquote(key), value_bytes | unquote(vars.acc)],
            unquote(vars.acc_size) + unquote(key_size) + value_bytes_size
          }
        end
    end
  end

  defp make_encode_field_body(%Field{kind: :packed} = field, _required, _syntax, vars) do
    {key_bytes, key_size} = Protox.Encode.make_key_bytes(field.tag, :packed)
    encode_packed_ast = make_encode_packed_body(field.type)

    quote do
      _generator = unquote(make_generator(__ENV__))

      case unquote(vars.msg).unquote(field.name) do
        [] ->
          {unquote(vars.acc), unquote(vars.acc_size)}

        values ->
          {packed_bytes, packed_size} = unquote(encode_packed_ast)

          {
            [unquote(key_bytes), packed_bytes | unquote(vars.acc)],
            unquote(vars.acc_size) + unquote(key_size) + packed_size
          }
      end
    end
  end

  defp make_encode_field_body(%Field{kind: :unpacked} = field, _required, _syntax, vars) do
    encode_repeated_ast = make_encode_repeated_body(field.tag, field.type)

    quote do
      _generator = unquote(make_generator(__ENV__))

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
      _generator = unquote(make_generator(__ENV__))

      map = Map.fetch!(unquote(vars.msg), unquote(field.name))

      if map_size(map) == 0 do
        {unquote(vars.acc), unquote(vars.acc_size)}
      else
        Enum.reduce(
          map,
          {unquote(vars.acc), unquote(vars.acc_size)},
          fn {unquote(k_var), unquote(v_var)}, {unquote(vars.acc), unquote(vars.acc_size)} ->
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
          end
        )
      end
    end
  end

  defp make_encode_unknown_fields_fun(vars, opts) do
    unknown_fields_name = Keyword.fetch!(opts, :unknown_fields_name)

    quote do
      defp encode_unknown_fields({unquote(vars.acc), unquote(vars.acc_size)}, msg) do
        _generator = unquote(make_generator(__ENV__))

        Enum.reduce(
          msg.unquote(unknown_fields_name),
          {unquote(vars.acc), unquote(vars.acc_size)},
          fn {tag, wire_type, bytes}, {unquote(vars.acc), unquote(vars.acc_size)} ->
            case wire_type do
              0 ->
                {key_bytes, key_size} = Protox.Encode.make_key_bytes(tag, :int32)

                {
                  [unquote(vars.acc), <<key_bytes::binary, bytes::binary>>],
                  unquote(vars.acc_size) + key_size + byte_size(bytes)
                }

              1 ->
                {key_bytes, key_size} = Protox.Encode.make_key_bytes(tag, :double)

                {
                  [unquote(vars.acc), <<key_bytes::binary, bytes::binary>>],
                  unquote(vars.acc_size) + key_size + byte_size(bytes)
                }

              2 ->
                {len_bytes, len_size} = bytes |> byte_size() |> Protox.Varint.encode()
                {key_bytes, key_size} = Protox.Encode.make_key_bytes(tag, :packed)

                {
                  [unquote(vars.acc), <<key_bytes::binary, len_bytes::binary, bytes::binary>>],
                  unquote(vars.acc_size) + key_size + len_size + byte_size(bytes)
                }

              5 ->
                {key_bytes, key_size} = Protox.Encode.make_key_bytes(tag, :float)

                {
                  [unquote(vars.acc), <<key_bytes::binary, bytes::binary>>],
                  unquote(vars.acc_size) + key_size + byte_size(bytes)
                }
            end
          end
        )
      end
    end
  end

  defp make_encode_packed_body(type) do
    value_var = Macro.var(:value, __MODULE__)
    encode_value_ast = get_encode_value_body(type, value_var)

    quote do
      _generator = unquote(make_generator(__ENV__))

      {value_bytes, value_size} =
        Enum.reduce(
          values,
          {_local_acc = [], _local_acc_size = 0},
          fn unquote(value_var), {local_acc, local_acc_size} ->
            {value_bytes, value_bytes_size} = unquote(encode_value_ast)

            {
              [value_bytes | local_acc],
              local_acc_size + value_bytes_size
            }
          end
        )

      {value_size_bytes, value_size_size} = Protox.Varint.encode(value_size)

      {[value_size_bytes, Enum.reverse(value_bytes)], value_size + value_size_size}
    end
  end

  defp make_encode_repeated_body(tag, type) do
    {key_bytes, key_bytes_sz} = Protox.Encode.make_key_bytes(tag, type)
    value_var = Macro.var(:value, __MODULE__)
    encode_value_ast = get_encode_value_body(type, value_var)

    quote do
      _generator = unquote(make_generator(__ENV__))

      {value_bytes, value_size} =
        Enum.reduce(
          values,
          {_local_acc = [], _local_acc_size = 0},
          fn unquote(value_var), {local_acc, local_acc_size} ->
            {value_bytes, value_bytes_size} = unquote(encode_value_ast)

            {
              [value_bytes, unquote(key_bytes) | local_acc],
              local_acc_size + unquote(key_bytes_sz) + value_bytes_size
            }
          end
        )

      {Enum.reverse(value_bytes), value_size}
    end
  end

  defp get_encode_value_body({:message, _}, value_var) do
    quote do
      Protox.Encode.encode_message(unquote(value_var))
    end
  end

  defp get_encode_value_body({:enum, enum}, value_var) do
    quote do
      unquote(value_var) |> unquote(enum).encode() |> Protox.Encode.encode_enum()
    end
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

  defp get_encode_value_body(:int32, value_var) do
    quote(do: Protox.Encode.encode_int32(unquote(value_var)))
  end

  defp get_encode_value_body(:int64, value_var) do
    quote(do: Protox.Encode.encode_int64(unquote(value_var)))
  end

  defp get_encode_value_body(:uint32, value_var) do
    quote(do: Protox.Encode.encode_uint32(unquote(value_var)))
  end

  defp get_encode_value_body(:uint64, value_var) do
    quote(do: Protox.Encode.encode_uint64(unquote(value_var)))
  end

  defp get_encode_value_body(:sint32, value_var) do
    quote(do: Protox.Encode.encode_sint32(unquote(value_var)))
  end

  defp get_encode_value_body(:sint64, value_var) do
    quote(do: Protox.Encode.encode_sint64(unquote(value_var)))
  end

  defp get_encode_value_body(:fixed32, value_var) do
    quote(do: Protox.Encode.encode_fixed32(unquote(value_var)))
  end

  defp get_encode_value_body(:fixed64, value_var) do
    quote(do: Protox.Encode.encode_fixed64(unquote(value_var)))
  end

  defp get_encode_value_body(:sfixed32, value_var) do
    quote(do: Protox.Encode.encode_sfixed32(unquote(value_var)))
  end

  defp get_encode_value_body(:sfixed64, value_var) do
    quote(do: Protox.Encode.encode_sfixed64(unquote(value_var)))
  end

  defp get_encode_value_body(:float, value_var) do
    quote(do: Protox.Encode.encode_float(unquote(value_var)))
  end

  defp get_encode_value_body(:double, value_var) do
    quote(do: Protox.Encode.encode_double(unquote(value_var)))
  end

  defp make_encode_field_fun_name(field) when is_atom(field) do
    String.to_atom("encode_#{field}")
  end

  defp make_generator(%Macro.Env{} = env) do
    {fun_name, _fun_arity} = env.function
    "#{fun_name}:#{env.line}"
  end

  defp get_required_fields(fields) do
    for %Field{label: :required, name: name} <- fields, do: name
  end
end
