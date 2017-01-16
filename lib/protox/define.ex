defmodule Protox.Define do

  @moduledoc false
  # Generates structs from message and enumeration definitions.

  defmacro __using__(enums: enums, messages: messages) do
    define(
      enums    |> Code.eval_quoted() |> elem(0),
      messages |> Code.eval_quoted() |> elem(0)
    )
  end


  def define(enums, messages) do
    define_enums(enums) ++ define_messages(messages)
  end


  # -- Private


  defp define_enums(enums) do
    for {enum_name, constants} <- enums do

      default_fun           = make_enum_default(constants)
      encode_constants_funs = make_encode_enum_constants(constants)
      decode_constants_funs = make_decode_enum_constants(constants)

      quote do
        defmodule unquote(enum_name) do
          @moduledoc false

          unquote(default_fun)

          unquote(encode_constants_funs)
          def encode(x), do: x

          unquote(decode_constants_funs)
          def decode(x), do: x

          def constants(), do: unquote(constants)
        end
      end

    end
  end


  defp define_messages(messages) do
    for {msg_name, fields} <- messages do

      unknown_fields  = make_unknown_fields(:__unknown_fields__, fields)
      struct_fields   = make_struct_fields(fields, unknown_fields)
      required_fields = make_required_fields(fields)
      fields_map      = make_fields_map(fields)
      encoder         = Protox.DefineEncoder.define(fields)

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


          def defs(), do: unquote(fields_map)


          def get_required_fields(), do: unquote(required_fields)


          def get_unknown_fields(msg)  , do: msg.unquote(unknown_fields)
          def get_unknown_fields_name(), do: unquote(unknown_fields)
          def clear_unknown_fields(msg), do: struct!(msg, [{get_unknown_fields_name(), []}])

        end # module
      end
    end # for
  end


  # -- Enum


  # Make sure the name chosen for the struct fields that stores the unknow fields
  # of the protobuf message doesn't collide with already existing names.
  defp make_unknown_fields(name, fields) do
    name_in_fields = Enum.find(fields, fn {_, _, n, _, _} -> n == name end)
    if name_in_fields do
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
    for {value, constant} <- (Map.new(constant_values)) do
      quote do
        def decode(unquote(value)), do: unquote(constant)
      end
    end
  end


  # Generate fields of the struct which is created for a message.
  defp make_struct_fields(fields, unknown_fields) do
    for {_, _, name, kind, _} <- fields do
      case kind do
        :map                      -> {name, Macro.escape(%{})}
        {:oneof, parent}          -> {parent, nil}
        :packed                   -> {name, []}
        :unpacked                 -> {name, []}
        {:default, default_value} -> {name, default_value}
      end
    end
    ++
    [{unknown_fields, []}]
  end


  # Get the list of fields that are marked as `required`.
  defp make_required_fields(fields) do
    for {_, :required, name, _, _} <- fields, do: name
  end


  # Generate a map used to store a message's definitions.
  defp make_fields_map(fields) do
    fields
    |> Enum.reduce(%{},
      fn ({tag, _, name, kind, type}, acc) ->
        ty = case {kind, type} do
          {:map, {key_type, {:message, msg}}} -> {key_type, {:message, msg}}
          {:map, {key_type, {:enum, enum}}}   -> {key_type, {:enum, enum}}
          {_, {:enum, enum}}                  -> {:enum, enum}
          {_, {:message, msg}}                -> {:message, msg}
          {_, ty}                             -> ty
        end
        Map.put(acc, tag, {name, kind, ty})
      end)
    |> Macro.escape()
  end

end
