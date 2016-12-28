defmodule Protox.Define do

  @moduledoc """
  Generates struct from message and enumeration definitions.
  The encoding function is also generated for each message.
  """


  defmacro __using__(enums: enums, messages: messages) do
    # Cleanup enums and messages to remove macro related stuff. Somehow, it feels wrong.
    # There's must a better way to do this.

    enums_p = Enum.map(enums,
      fn {{_, _, name}, constant_values} ->
       {name, constant_values}
      end)

    messages_p = Enum.map(messages,
      fn {{_, _, name}, fs} ->
        fields = for {_, _, f} <- fs do
          case List.to_tuple(f) do
            {tag, label, name, kind, {enum_or_msg, {_, _, emname}}} ->
              {tag, label, name, kind, {enum_or_msg, emname}}

            {tag, label, name, :map, {key_type, {enum_or_msg, {_, _, emname}}}} ->
              {tag, label, name, :map, {key_type, {enum_or_msg, emname}}}

            t ->
              t
          end
        end

        {name, fields}
     end)

    define(enums_p, messages_p)
  end


  def define(enums, messages) do
    define_enums(enums) ++ define_messages(messages)
  end


  # -- Private


  defp define_enums(enums) do
    for {name, constants} <- enums do

      enum_name             = Module.concat(name)
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
    for {name, fields} <- messages do

      msg_name       = Module.concat(name)
      struct_fields  = make_struct_fields(fields)
      required       = get_required_fields(fields)
      fields_map     = make_fields_map(fields)
      encoder        = Protox.DefineEncoder.define(fields)

      quote do
        defmodule unquote(msg_name) do
          @moduledoc false

          import Protox.Encode


          # Use @enforce_keys for protobuf 2 `required` fields.
          @enforce_keys unquote(required)
          defstruct unquote(struct_fields)


          # The encoding function is generated for each message.
          unquote(encoder)


          @spec encode_binary(struct) :: binary
          def encode_binary(msg = %unquote(msg_name){}) do
            Protox.Encode.encode_binary(msg)
          end


          @spec decode!(binary) :: struct | no_return
          def decode!(bytes) do
            Protox.Decode.decode!(bytes, unquote(msg_name))
          end


          @spec decode(binary) :: {:ok, struct} | {:error, any}
          def decode(bytes) do
            Protox.Decode.decode(bytes, unquote(msg_name))
          end


          def defs(), do: unquote(fields_map)

        end # module
      end
    end # for
  end


  # -- Enum


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


  # Generate fields of the struct which is create for a message.
  defp make_struct_fields(fields) do
    for {_, _, name, kind, _} <- fields do
      case kind do
        :map                      -> {name, Macro.escape(%{})}
        {:oneof, parent}          -> {parent, nil}
        :packed                   -> {name, []}
        :unpacked                 -> {name, []}
        {:default, default_value} -> {name, default_value}
      end
    end
  end


  # Get the list of fields that are marked as `required`.
  defp get_required_fields(fields) do
    for {_, :required, name, _, _} <- fields, do: name
  end


  # Generate a map used to store a message's definitions.
  defp make_fields_map(fields) do
    fields
    |> Enum.reduce(%{},
      fn ({tag, _, name, kind, type}, acc) ->
        ty = case {kind, type} do
          {:map, {key_type, {:message, msg}}} -> {key_type, {:message, msg |> Module.concat()}}
          {:map, {key_type, {:enum, enum}}}   -> {key_type, {:enum, Module.concat(enum)}}
          {_, {:enum, enum}}                  -> {:enum, Module.concat(enum)}
          {_, {:message, msg}}                -> {:message, msg |> Module.concat()}
          {_, ty}                             -> ty
        end
        Map.put(acc, tag, {name, kind, ty})
      end)
    |> Macro.escape()
  end

end
