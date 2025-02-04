defmodule Protox.DefineMessage do
  @moduledoc false

  alias Protox.{Field, OneOf, Scalar}

  def define(messages, opts \\ []) do
    for {_msg_name, msg = %Protox.Message{}} <- messages do
      # Revert the order of the fields so we iterate from last field to first.
      # This enables us to construct the output iodata using [ field | acc ]
      sorted_fields = msg.fields |> Map.values() |> Enum.sort(&(&1.tag >= &2.tag))

      required_fields = get_required_fields(sorted_fields)
      unknown_fields_name = make_unknown_fields_name(:__uf__, sorted_fields)
      opts = Keyword.put(opts, :unknown_fields_name, unknown_fields_name)

      struct_fields = make_struct_fields(sorted_fields, msg.syntax, unknown_fields_name)

      unknown_fields_funs = make_unknown_fields_funs(unknown_fields_name)
      default_fun = make_default_funs(sorted_fields)

      encoder = Protox.DefineEncoder.define(sorted_fields, required_fields, msg.syntax, opts)
      decoder = Protox.DefineDecoder.define(msg.name, sorted_fields, required_fields, opts)

      quote do
        defmodule unquote(msg.name) do
          @moduledoc false

          defstruct unquote(struct_fields)

          unquote(encoder)
          unquote(decoder)
          unquote(unknown_fields_funs)
          unquote(default_fun)

          @spec schema() :: Protox.Message.t()
          def schema(), do: unquote(Macro.escape(msg))
        end
      end
    end
  end

  # -- Private

  defp make_unknown_fields_funs(unknown_fields) do
    quote do
      @spec unknown_fields(struct()) :: [{non_neg_integer(), Protox.Types.tag(), binary()}]
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
      |> (fn x -> x <> "_" end).()
      |> String.to_atom()
      |> make_unknown_fields_name(fields)
    else
      base_name
    end
  end

  # Generate fields of the struct which is created for a message.
  defp make_struct_fields(fields, syntax, unknown_fields_name) do
    struct_fields =
      for %Field{label: label, name: name, kind: kind} <- fields do
        case kind do
          :map -> {name, Macro.escape(%{})}
          %OneOf{parent: parent} -> make_oneof_field(label, name, parent)
          :packed -> {name, []}
          :unpacked -> {name, []}
          %Scalar{} when syntax == :proto2 -> {name, nil}
          %Scalar{default_value: default_value} when syntax == :proto3 -> {name, default_value}
        end
      end

    Enum.uniq(struct_fields ++ [{unknown_fields_name, []}])
  end

  defp make_oneof_field(:proto3_optional, name, _), do: {name, nil}
  defp make_oneof_field(_, _, parent), do: {parent, nil}

  defp get_required_fields(fields) do
    for %Field{label: :required, name: name} <- fields, do: name
  end
end
