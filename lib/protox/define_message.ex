defmodule Protox.DefineMessage do
  @moduledoc false

  alias Protox.{Field, OneOf, Scalar}

  @base_unknown_fields_name :__uf__

  def define(messages_schemas, opts \\ []) do
    for {_msg_name, %Protox.MessageSchema{} = msg_schema} <- messages_schemas do
      msg_schema = cleanup_file_options(msg_schema)

      # Revert the order of the fields so we iterate from last field to first.
      # This enables us to construct the output iodata using [ field | acc ]
      sorted_fields = msg_schema.fields |> Map.values() |> Enum.sort(&(&1.tag >= &2.tag))

      unknown_fields_name = make_unknown_fields_name(@base_unknown_fields_name, sorted_fields)
      opts = Keyword.put(opts, :unknown_fields_name, unknown_fields_name)

      struct_fields_types =
        make_struct_fields_types(sorted_fields, msg_schema.syntax, unknown_fields_name)

      struct_fields = make_struct_fields(sorted_fields, msg_schema.syntax, unknown_fields_name)

      unknown_fields_funs = make_unknown_fields_funs(unknown_fields_name)
      default_fun = make_default_funs(sorted_fields)

      encoder = Protox.DefineEncoder.define(sorted_fields, msg_schema.syntax, opts)
      decoder = Protox.DefineDecoder.define(msg_schema.name, sorted_fields, opts)

      quote do
        defmodule unquote(msg_schema.name) do
          @moduledoc false

          if function_exported?(Protox, :check_generator_version, 1) do
            Protox.check_generator_version(unquote(Protox.generator_version()))
          else
            raise "This code was generated with protox 2 but the runtime is using an older version of protox."
          end

          unquote(struct_fields_types)
          defstruct unquote(struct_fields)

          unquote(encoder)
          unquote(decoder)
          unquote(unknown_fields_funs)
          unquote(default_fun)

          @spec schema() :: Protox.MessageSchema.t()
          def schema(), do: unquote(Macro.escape(msg_schema))
        end
      end
    end
  end

  # -- Private

  defp make_unknown_fields_funs(unknown_fields) do
    quote do
      @spec unknown_fields(struct()) :: unquote(unknown_fields_type())
      def unknown_fields(msg), do: msg.unquote(unknown_fields)

      @spec unknown_fields_name() :: unquote(unknown_fields)
      def unknown_fields_name(), do: unquote(unknown_fields)

      @spec clear_unknown_fields(struct) :: struct
      def clear_unknown_fields(msg), do: struct!(msg, [{unquote(unknown_fields), []}])
    end
  end

  # Generate the functions that provide a direct access to the default value of a field.
  defp make_default_funs(fields) do
    all_default_funs =
      Enum.map(fields, fn
        %Field{name: name, kind: %Scalar{default_value: default}} ->
          quote do
            def default(unquote(name)), do: {:ok, unquote(default)}
          end

        %Field{name: name} ->
          quote do
            def default(unquote(name)), do: {:error, :no_default_value}
          end
      end)

    quote do
      @spec default(atom()) ::
              {:ok, boolean() | integer() | String.t() | float()}
              | {:error, :no_such_field | :no_default_value}

      unquote_splicing(all_default_funs)

      def default(_), do: {:error, :no_such_field}
    end
  end

  # Make sure the name chosen for the struct fields that stores the unknow fields
  # of the protobuf message doesn't collide with already existing names.
  defp make_unknown_fields_name(base_name, fields) do
    name_in_fields = Enum.find(fields, fn %Field{name: n} -> n == base_name end)

    if name_in_fields do
      # Append a '_' while there's a collision
      base_name
      |> Atom.to_string()
      |> then(fn x -> x <> "_" end)
      |> String.to_atom()
      |> make_unknown_fields_name(fields)
    else
      base_name
    end
  end

  # Generate fields of the struct which is created for a message.
  defp make_struct_fields(fields, syntax, unknown_fields_name) do
    struct_fields =
      for %Field{kind: kind} = field <- fields do
        case kind do
          :map -> {field.name, Macro.escape(%{})}
          %OneOf{parent: parent} -> make_oneof_field(field.label, field.name, parent)
          :packed -> {field.name, []}
          :unpacked -> {field.name, []}
          %Scalar{} when syntax == :proto2 -> {field.name, nil}
          %Scalar{default_value: default_value} when syntax == :proto3 -> {field.name, default_value}
        end
      end

    Enum.uniq(struct_fields ++ [{unknown_fields_name, []}])
  end

  defp make_struct_fields_types(fields, syntax, unknown_fields_name) do
    %{oneofs: grouped_oneofs, proto3_optionals: proto3_optionals, others: fields} =
      Protox.Defs.split_oneofs(fields)

    fields_types =
      for %Field{} = field <- fields do
        case {field.kind, field.type} do
          {:map, type} ->
            key_type = type |> elem(0) |> proto_type_to_typespec()
            value_type = type |> elem(1) |> proto_type_to_typespec()
            quote(do: {unquote(field.name), %{unquote(key_type) => unquote(value_type)}})

          {repeated, type} when repeated in [:packed, :unpacked] ->
            value_type = proto_type_to_typespec(type)
            quote(do: {unquote(field.name), [unquote(value_type)]})

          {%Scalar{}, type} when syntax == :proto2 ->
            value_type = proto_type_to_typespec(type)
            quote(do: {unquote(field.name), unquote(value_type) | nil})

          {%Scalar{}, {:message, _} = type} ->
            value_type = proto_type_to_typespec(type)
            quote(do: {unquote(field.name), unquote(value_type) | nil})

          {%Scalar{}, type} ->
            value_type = proto_type_to_typespec(type)
            quote(do: {unquote(field.name), unquote(value_type)})
        end
      end

    oneofs_fields_types =
      for {parent_name, children} <- grouped_oneofs do
        children_types =
          Enum.reduce(children, nil, fn child, acc ->
            child_type = proto_type_to_typespec(child.type)
            {:|, [], [{child.name, child_type}, acc]}
          end)

        quote do
          {unquote(parent_name), unquote(children_types)}
        end
      end

    proto3_optionals_types =
      for %Field{} = field <- proto3_optionals do
        quote do
          {unquote(field.name), unquote(proto_type_to_typespec(field.type)) | nil}
        end
      end

    all_fields_types =
      fields_types ++
        oneofs_fields_types ++
        proto3_optionals_types ++
        [quote(do: {unquote(unknown_fields_name), unquote(unknown_fields_type())})]

    quote do
      @type t :: %__MODULE__{unquote_splicing(all_fields_types)}
    end
  end

  defp make_oneof_field(:proto3_optional, name, _), do: {name, nil}
  defp make_oneof_field(_, _, parent), do: {parent, nil}

  defp proto_type_to_typespec(:string), do: quote(do: String.t())
  defp proto_type_to_typespec(:bytes), do: quote(do: binary())
  defp proto_type_to_typespec({:enum, _enum}), do: quote(do: atom())
  defp proto_type_to_typespec({:message, message}), do: quote(do: unquote(message).t())
  defp proto_type_to_typespec(:bool), do: quote(do: boolean())
  defp proto_type_to_typespec(:double), do: quote(do: float())
  defp proto_type_to_typespec(:float), do: quote(do: float())
  defp proto_type_to_typespec(:sfixed32), do: quote(do: integer())
  defp proto_type_to_typespec(:sfixed64), do: quote(do: integer())
  defp proto_type_to_typespec(:fixed32), do: quote(do: integer())
  defp proto_type_to_typespec(:fixed64), do: quote(do: integer())
  defp proto_type_to_typespec(:int32), do: quote(do: integer())
  defp proto_type_to_typespec(:int64), do: quote(do: integer())
  defp proto_type_to_typespec(:sint32), do: quote(do: integer())
  defp proto_type_to_typespec(:sint64), do: quote(do: integer())
  defp proto_type_to_typespec(:uint32), do: quote(do: non_neg_integer())
  defp proto_type_to_typespec(:uint64), do: quote(do: non_neg_integer())

  defp unknown_fields_type() do
    quote do
      [{non_neg_integer(), Protox.Types.tag(), binary()}]
    end
  end

  defp cleanup_file_options(schema) do
    # If it exists, transform :file_options into a bare map so as to not depend
    # on the FileOptions type which is not necessary for the end user.
    # Also, remove the unknown fields field which will always be empty in this case.

    update_in(schema, [Access.key!(:file_options)], fn
      nil -> nil
      struct -> struct |> Map.from_struct() |> Map.delete(@base_unknown_fields_name)
    end)
  end
end
