defmodule Protox.DefineMessage do
  @moduledoc false

  alias Protox.Field

  def define(messages, opts \\ []) do
    {keep_unknown_fields, _opts} = Keyword.pop(opts, :keep_unknown_fields, true)

    for {msg_name, syntax, fields} <- messages do
      fields = Enum.sort(fields, &(&1.tag < &2.tag))

      unknown_fields = make_unknown_fields(:__uf__, fields)
      unknown_fields_funs = make_unknown_fields_funs(keep_unknown_fields, unknown_fields)

      struct_fields = make_struct_fields(fields, syntax, unknown_fields, keep_unknown_fields)

      required_fields = make_required_fields(fields)
      required_fields_typesecs = make_required_fields_typespec(required_fields)

      fields_map = make_fields_map(fields)
      fields_by_name_map = make_fields_by_name_map(fields)

      encoder = Protox.DefineEncoder.define(fields, required_fields, syntax, opts)
      decoder = Protox.DefineDecoder.define(msg_name, fields, required_fields, opts)

      default_fun = make_default_fun(fields)

      module_ast =
        quote do
          defstruct unquote(struct_fields)

          unquote(encoder)
          unquote(decoder)

          @deprecated "Use fields/0 instead"
          @spec defs() :: %{
                  required(non_neg_integer) => {atom, Protox.Types.kind(), Protox.Types.type()}
                }
          def defs(), do: unquote(fields_map)

          @deprecated "Use fields/0 instead"
          @spec defs_by_name() :: %{
                  required(atom) => {non_neg_integer, Protox.Types.kind(), Protox.Types.type()}
                }
          def defs_by_name(), do: unquote(fields_by_name_map)

          @spec fields() :: list(Protox.Field.t())
          def fields(), do: unquote(Macro.escape(fields))

          unquote(unknown_fields_funs)

          @spec required_fields() :: unquote(required_fields_typesecs)
          def required_fields(), do: unquote(required_fields)

          @spec syntax() :: atom
          def syntax(), do: unquote(syntax)

          unquote(default_fun)
        end

      quote do
        defmodule unquote(msg_name) do
          @moduledoc false
          unquote(module_ast)
        end
      end
    end
  end

  defp make_unknown_fields_funs(true = _keep_unknown_fields, unknown_fields) do
    quote do
      @spec unknown_fields(struct) :: [{non_neg_integer, Protox.Types.tag(), binary}]
      def unknown_fields(msg), do: msg.unquote(unknown_fields)

      @spec unknown_fields_name() :: unquote(unknown_fields)
      def unknown_fields_name(), do: unquote(unknown_fields)

      @spec clear_unknown_fields(struct) :: struct
      def clear_unknown_fields(msg), do: struct!(msg, [{unknown_fields_name(), []}])
    end
  end

  defp make_unknown_fields_funs(false = _keep_unknown_fields, _unknown_fields) do
    []
  end

  defp make_default_fun(fields) do
    spec =
      quote do
        @spec default(atom) :: {:ok, boolean | integer | String.t() | float} | {:error, atom}
      end

    match_all =
      quote do
        def default(_), do: {:error, :no_such_field}
      end

    ast =
      Enum.map(fields, fn
        %Field{name: name, kind: {:default, default}} ->
          quote do
            def default(unquote(name)), do: {:ok, unquote(default)}
          end

        %Field{name: name} ->
          quote do
            def default(unquote(name)), do: {:error, :no_default_value}
          end
      end)

    List.flatten([spec, ast, match_all])
  end

  # Make sure the name chosen for the struct fields that stores the unknow fields
  # of the protobuf message doesn't collide with already existing names.
  defp make_unknown_fields(name, fields) do
    name_in_fields = Enum.find(fields, fn %Field{name: n} -> n == name end)

    if name_in_fields do
      # Append a '_' while there's a collision
      name
      |> Atom.to_string()
      |> (fn x -> x <> "_" end).()
      |> String.to_atom()
      |> make_unknown_fields(fields)
    else
      name
    end
  end

  # Generate fields of the struct which is created for a message.
  defp make_struct_fields(fields, syntax, unknown_fields, keep_unknown_fields) do
    struct_fields =
      for %Field{label: label, name: name, kind: kind} <- fields do
        case kind do
          :map -> {name, Macro.escape(%{})}
          {:oneof, parent} -> make_oneof_field(label, name, parent)
          :packed -> {name, []}
          :unpacked -> {name, []}
          {:default, _} when syntax == :proto2 -> {name, nil}
          {:default, default_value} when syntax == :proto3 -> {name, default_value}
        end
      end

    struct_fields =
      case keep_unknown_fields do
        true -> struct_fields ++ [{unknown_fields, []}]
        false -> struct_fields
      end

    Enum.uniq(struct_fields)
  end

  defp make_oneof_field(:proto3_optional, name, _), do: {name, nil}
  defp make_oneof_field(_, _, parent), do: {parent, nil}

  # Get the list of fields that are marked as `required`.
  defp make_required_fields(fields) do
    for %Field{label: :required, name: name} <- fields, do: name
  end

  defp make_required_fields_typespec([]) do
    quote do: []
  end

  defp make_required_fields_typespec(fields) do
    specs =
      Enum.reduce(
        fields,
        fn field, acc ->
          quote do: unquote(acc) | unquote(field)
        end
      )

    quote do: [unquote(specs)]
  end

  # Generate a map used to store a message's definitions.
  defp make_fields_map(fields) do
    fields
    |> Enum.reduce(%{}, fn %Field{tag: tag, name: name, kind: kind, type: type}, acc ->
      Map.put(acc, tag, {name, kind, make_type_field(kind, type)})
    end)
    |> Macro.escape()
  end

  defp make_fields_by_name_map(fields) do
    fields
    |> Enum.reduce(%{}, fn %Field{tag: tag, name: name, kind: kind, type: type}, acc ->
      Map.put(acc, name, {tag, kind, make_type_field(kind, type)})
    end)
    |> Macro.escape()
  end

  defp make_type_field(:map, {key_type, {:message, msg}}), do: {key_type, {:message, msg}}
  defp make_type_field(:map, {key_type, {:enum, enum}}), do: {key_type, {:enum, enum}}
  defp make_type_field(_, {:enum, enum}), do: {:enum, enum}
  defp make_type_field(_, {:message, enum}), do: {:message, enum}
  defp make_type_field(_, ty), do: ty
end
