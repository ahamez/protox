defmodule Protox.DefineMessage do
  @moduledoc false

  alias Protox.Field

  def define(messages, opts \\ []) do
    keep_unknown_fields = Keyword.get(opts, :keep_unknown_fields, true)
    generate_defs_funs = Keyword.get(opts, :generate_defs_funs, true)

    for {msg_name, syntax, fields} <- messages do
      fields = Enum.sort(fields, &(&1.tag < &2.tag))

      unknown_fields = make_unknown_fields(:__uf__, fields)
      unknown_fields_funs = make_unknown_fields_funs(keep_unknown_fields, unknown_fields)

      struct_fields = make_struct_fields(fields, syntax, unknown_fields, keep_unknown_fields)

      required_fields = make_required_fields(fields)
      required_fields_typesecs = make_required_fields_typespec(required_fields)

      defs_funs = make_defs_funs(fields, generate_defs_funs)
      field_def_funs = make_field_funs(fields)

      encoder = Protox.DefineEncoder.define(fields, required_fields, syntax, opts)
      decoder = Protox.DefineDecoder.define(msg_name, fields, required_fields, opts)

      json_funs = make_json_funs(msg_name)

      default_fun = make_default_funs(fields)

      module_ast =
        quote do
          defstruct unquote(struct_fields)

          unquote(encoder)
          unquote(decoder)

          unquote(json_funs)

          unquote(defs_funs)

          @spec fields_defs() :: list(Protox.Field.t())
          def fields_defs(), do: unquote(Macro.escape(fields))

          unquote(field_def_funs)

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

  # -- Private

  defp make_defs_funs(_fields, false = _generate_defs_funs), do: []

  defp make_defs_funs(fields, true = _generate_defs_funs) do
    fields_map = make_fields_map(fields)
    fields_by_name_map = make_fields_by_name_map(fields)

    quote do
      @deprecated "Use fields_defs()/0 instead"
      @spec defs() :: %{
              required(non_neg_integer) => {atom, Protox.Types.kind(), Protox.Types.type()}
            }
      def defs(), do: unquote(fields_map)

      @deprecated "Use fields_defs()/0 instead"
      @spec defs_by_name() :: %{
              required(atom) => {non_neg_integer, Protox.Types.kind(), Protox.Types.type()}
            }
      def defs_by_name(), do: unquote(fields_by_name_map)
    end
  end

  defp make_json_funs(msg_name) do
    quote do
      @spec json_decode(iodata(), keyword()) :: {:ok, struct()} | {:error, any()}
      def json_decode(input, opts \\ []) do
        try do
          {:ok, json_decode!(input, opts)}
        rescue
          e in Protox.JsonDecodingError ->
            {:error, e}
        end
      end

      @spec json_decode!(iodata(), keyword()) :: struct() | no_return()
      def json_decode!(input, opts \\ []) do
        {json_library_wrapper, json_library} = Protox.JsonLibrary.get_library(opts, :decode)

        Protox.JsonDecode.decode!(
          input,
          unquote(msg_name),
          &json_library_wrapper.decode!(json_library, &1)
        )
      end

      @spec json_encode(struct(), keyword()) :: {:ok, iodata()} | {:error, any()}
      def json_encode(msg, opts \\ []) do
        try do
          {:ok, json_encode!(msg, opts)}
        rescue
          e in Protox.JsonEncodingError ->
            {:error, e}
        end
      end

      @spec json_encode!(struct(), keyword()) :: iodata() | no_return()
      def json_encode!(msg, opts \\ []) do
        {json_library_wrapper, json_library} = Protox.JsonLibrary.get_library(opts, :encode)

        Protox.JsonEncode.encode!(msg, &json_library_wrapper.encode!(json_library, &1))
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

  # Generate the functions that provide a direct access to the default value of a field.
  defp make_default_funs(fields) do
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
        %Field{name: name, kind: {:scalar, default}} ->
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

  # Generate the functions that provide a direct access to a field defininition.
  defp make_field_funs(fields) do
    spec =
      quote do
        @spec field_def(atom) :: {:ok, Protox.Field.t()} | {:error, :no_such_field}
      end

    match_all =
      quote do
        def field_def(_), do: {:error, :no_such_field}
      end

    ast =
      Enum.map(fields, fn %Field{} = field ->
        atom_name_as_string = Atom.to_string(field.name)

        maybe_fun_by_atom_name_as_string =
          if atom_name_as_string == field.json_name do
            []
          else
            quote do
              def field_def(unquote(atom_name_as_string)), do: {:ok, unquote(Macro.escape(field))}
            end
          end

        quote do
          def field_def(unquote(field.name)), do: {:ok, unquote(Macro.escape(field))}
          def field_def(unquote(field.json_name)), do: {:ok, unquote(Macro.escape(field))}
          unquote(maybe_fun_by_atom_name_as_string)
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
          {:scalar, _} when syntax == :proto2 -> {name, nil}
          {:scalar, default_value} when syntax == :proto3 -> {name, default_value}
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

  defp make_required_fields_typespec([]), do: quote(do: [])

  defp make_required_fields_typespec(fields) do
    specs =
      Enum.reduce(
        fields,
        fn field, acc ->
          quote(do: unquote(acc) | unquote(field))
        end
      )

    quote(do: [unquote(specs)])
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
