defmodule Protox.Define do
  @moduledoc false
  # Generates structs from message and enumeration definitions.

  defmacro __using__(enums: enums, messages: messages) do
    define(
      enums |> Code.eval_quoted() |> elem(0),
      messages |> Code.eval_quoted() |> elem(0)
    )
  end

  def define(enums, messages) do
    define_enums(enums) ++ define_messages(messages)
  end

  # -- Private

  defp define_enums(enums) do
    for {enum_name, constants} <- enums do
      default_fun = make_enum_default(constants)
      encode_constants_funs = make_encode_enum_constants(constants)
      decode_constants_funs = make_decode_enum_constants(constants)
      constants_typespec = make_constants_typespec(constants)

      quote do
        defmodule unquote(enum_name) do
          @moduledoc false

          unquote(default_fun)

          @spec encode(atom) :: integer
          unquote(encode_constants_funs)
          def encode(x), do: x

          @spec decode(integer) :: atom
          unquote(decode_constants_funs)
          def decode(x), do: x

          @spec constants() :: unquote(constants_typespec)
          def constants(), do: unquote(constants)
        end
      end
    end
  end

  defp make_constants_typespec(constants) do
    lhs = Enum.reduce(constants, fn {x, _}, acc -> quote do: unquote(acc) | unquote(x) end)
    rhs = Enum.reduce(constants, fn {_, y}, acc -> quote do: unquote(acc) | unquote(y) end)
    quote do: [{unquote(lhs), unquote(rhs)}]
  end

  defp define_messages(messages) do
    for {msg_name, fields} <- messages do
      unknown_fields = make_unknown_fields(:__uf__, fields)
      struct_fields = make_struct_fields(fields, unknown_fields)
      required_fields = make_required_fields(fields)
      required_fields_typesecs = make_required_fields_typespec(required_fields)
      fields_map = make_fields_map(fields)
      encoder = Protox.DefineEncoder.define(fields)

      quote do
        defmodule unquote(msg_name) do
          @moduledoc false

          import Protox.Encode

          defstruct unquote(struct_fields)

          # Encoding function is generated for each message.
          unquote(encoder)

          @spec decode!(binary) :: struct | no_return
          def decode!(bytes) do
            Protox.Decode.decode!(bytes, unquote(msg_name), unquote(required_fields))
          end

          @spec decode(binary) :: {:ok, struct} | {:error, any}
          def decode(bytes) do
            Protox.Decode.decode(bytes, unquote(msg_name), unquote(required_fields))
          end

          @spec defs() :: %{
                  required(non_neg_integer) => {atom, Protox.Types.kind(), Protox.Types.type()}
                }
          def defs(), do: unquote(fields_map)

          @spec get_required_fields() :: unquote(required_fields_typesecs)
          def get_required_fields(), do: unquote(required_fields)

          @spec get_unknown_fields(struct) :: [{non_neg_integer, Protox.Types.tag(), binary}]
          def get_unknown_fields(msg), do: msg.unquote(unknown_fields)

          @spec get_unknown_fields_name() :: unquote(unknown_fields)
          def get_unknown_fields_name(), do: unquote(unknown_fields)

          @spec clear_unknown_fields(struct) :: struct
          def clear_unknown_fields(msg), do: struct!(msg, [{get_unknown_fields_name(), []}])
        end

        # module
      end
    end

    # for
  end

  # -- Enum

  # Make sure the name chosen for the struct fields that stores the unknow fields
  # of the protobuf message doesn't collide with already existing names.
  defp make_unknown_fields(name, fields) do
    name_in_fields = Enum.find(fields, fn {_, _, n, _, _} -> n == name end)

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

  defp make_enum_default(constant_values) do
    [{_, default_value} | _] = constant_values

    quote do
      @spec default() :: unquote(default_value)
      def default(), do: unquote(default_value)
    end
  end

  defp make_encode_enum_constants(constant_values) do
    for {value, constant} <- constant_values do
      quote do
        def encode(unquote(constant)), do: unquote(value)
      end
    end
  end

  defp make_decode_enum_constants(constant_values) do
    # Map.new -> unify enum aliases
    for {value, constant} <- Map.new(constant_values) do
      quote do
        def decode(unquote(value)), do: unquote(constant)
      end
    end
  end

  # Generate fields of the struct which is created for a message.
  defp make_struct_fields(fields, unknown_fields) do
    for {_, _, name, kind, _} <- fields do
      case kind do
        :map -> {name, Macro.escape(%{})}
        {:oneof, parent} -> {parent, nil}
        :packed -> {name, []}
        :unpacked -> {name, []}
        {:default, default_value} -> {name, default_value}
      end
    end ++ [{unknown_fields, []}]
  end

  # Get the list of fields that are marked as `required`.
  defp make_required_fields(fields) do
    for {_, :required, name, _, _} <- fields, do: name
  end

  defp make_required_fields_typespec([]) do
    quote do: []
  end
  defp make_required_fields_typespec(fields) do
    specs = Enum.reduce(
              fields, 
              fn field, acc ->
                quote do: unquote(acc) | unquote(field)
              end)
    quote do: [unquote(specs)]
  end

  # Generate a map used to store a message's definitions.
  defp make_fields_map(fields) do
    fields
    |> Enum.reduce(%{}, fn {tag, _, name, kind, type}, acc ->
      Map.put(acc, tag, {name, kind, make_type_field(kind, type)})
    end)
    |> Macro.escape()
  end

  defp make_type_field(:map, {key_type, {:message, msg}}), do: {key_type, {:message, msg}}
  defp make_type_field(:map, {key_type, {:enum, enum}}), do: {key_type, {:enum, enum}}
  defp make_type_field(_, {:enum, enum}), do: {:enum, enum}
  defp make_type_field(_, {:message, enum}), do: {:message, enum}
  defp make_type_field(_, ty), do: ty
end
