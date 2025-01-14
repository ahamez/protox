defmodule Protox.DefineMessage do
  @moduledoc false

  alias Protox.Field

  def define(messages, opts \\ []) do
    keep_unknown_fields = Keyword.get(opts, :keep_unknown_fields, true)

    for msg = %Protox.Message{} <- messages do
      fields = Enum.sort(msg.fields, &(&1.tag < &2.tag))
      required_fields = make_required_fields(fields)
      unknown_fields_name = make_unknown_fields(:__uf__, fields)
      opts = Keyword.put(opts, :unknown_fields_name, unknown_fields_name)

      struct_fields =
        make_struct_fields(fields, msg.syntax, unknown_fields_name, keep_unknown_fields)

      unknown_fields_funs = make_unknown_fields_funs(unknown_fields_name, keep_unknown_fields)
      required_fields_fun = make_required_fields_fun(required_fields)
      fields_access_funs = make_fields_access_funs(fields)
      default_fun = make_default_funs(fields)
      syntax_fun = make_syntax_fun(msg.syntax)
      file_options_fun = make_file_options_fun(msg)

      encoder = Protox.DefineEncoder.define(fields, required_fields, msg.syntax, opts)
      decoder = Protox.DefineDecoder.define(msg.name, fields, required_fields, opts)

      quote do
        defmodule unquote(msg.name) do
          @moduledoc false

          defstruct unquote(struct_fields)

          unquote(encoder)
          unquote(decoder)
          unquote(fields_access_funs)
          unquote(unknown_fields_funs)
          unquote(required_fields_fun)
          unquote(syntax_fun)
          unquote(default_fun)
          unquote(file_options_fun)
        end
      end
    end
  end

  # -- Private

  defp make_file_options_fun(%Protox.Message{file_options: nil}) do
    quote do
      @spec file_options() :: nil
      def file_options(), do: nil
    end
  end

  defp make_file_options_fun(%Protox.Message{} = msg) do
    quote do
      @spec file_options() :: struct()
      def file_options() do
        file_options = unquote(Macro.escape(msg.file_options))

        # Google.Protobuf.FileOptions may be unknown at compilation time
        # as it's only generated if a file imports "google/protobuf/descriptor.proto".
        case function_exported?(Google.Protobuf.FileOptions, :decode!, 1) do
          true ->
            # When parsing a proto file, we must use the hardcoded version of
            # FileOptions contained in file descriptor.ex. However, it means that
            # extensions added on top on FileOptions to describe custom options can't
            # be decoded at this moment (they will be stored in the __uf__ field).
            #
            # Thus, we first encode them back to a binary form, then we decode them
            # with Google.Protobuf.FileOptions which contains the extensions
            # (note the missing `Protox` in front of the module name).

            bytes =
              file_options
              |> Protox.Google.Protobuf.FileOptions.encode!()
              |> :binary.list_to_bin()

            apply(Google.Protobuf.FileOptions, :decode!, [bytes])

          false ->
            file_options
        end
      end
    end
  end

  defp make_syntax_fun(syntax) do
    quote do
      @spec syntax() :: atom()
      def syntax(), do: unquote(syntax)
    end
  end

  defp make_unknown_fields_funs(unknown_fields, true = _keep_unknown_fields) do
    quote do
      @spec unknown_fields(struct) :: [{non_neg_integer, Protox.Types.tag(), binary}]
      def unknown_fields(msg), do: msg.unquote(unknown_fields)

      @spec unknown_fields_name() :: unquote(unknown_fields)
      def unknown_fields_name(), do: unquote(unknown_fields)

      @spec clear_unknown_fields(struct) :: struct
      def clear_unknown_fields(msg), do: struct!(msg, [{unquote(unknown_fields), []}])
    end
  end

  defp make_unknown_fields_funs(_unknown_fields, false = _keep_unknown_fields) do
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

  # Generate the functions that provide access to a field definition.
  defp make_fields_access_funs(fields) do
    quote do
      @spec fields_defs() :: list(Protox.Field.t())
      def fields_defs(), do: unquote(Macro.escape(fields))

      unquote(make_field_funs(fields))
    end
  end

  defp make_field_funs(fields) do
    spec =
      quote do
        @spec field_def(atom) :: {:ok, Protox.Field.t()} | {:error, :no_such_field}
      end

    no_such_field_case =
      quote do
        def field_def(_), do: {:error, :no_such_field}
      end

    ast =
      Enum.map(fields, fn %Field{} = field ->
        atom_name_as_string = Atom.to_string(field.name)

        quote do
          def field_def(unquote(field.name)), do: {:ok, unquote(Macro.escape(field))}
          def field_def(unquote(atom_name_as_string)), do: {:ok, unquote(Macro.escape(field))}
        end
      end)

    List.flatten([spec, ast, no_such_field_case])
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

  defp make_required_fields_fun(required_fields) do
    required_fields_typesecs = make_required_fields_typespec(required_fields)

    quote do
      @spec required_fields() :: unquote(required_fields_typesecs)
      def required_fields(), do: unquote(required_fields)
    end
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
end
