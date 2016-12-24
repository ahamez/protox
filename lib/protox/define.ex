defmodule Protox.Define do

  @moduledoc """
  Generates struct from message and enumeration definitions.
  The encoding function is also generated for each message.
  """


  defmacro __using__(enums: enums, messages: messages) do

    define(
      Enum.map(enums,
        fn {{_, _, name}, members} ->
          {name, members}
        end),
      Enum.map(messages,
       fn {{_, _, name}, fs} ->
          fields = for {_, _, f} <- fs, do: List.to_tuple(f)
          {name, fields}
       end)
    )
  end


  # -- Private


  def define(enums, messages) do

    for {name, members} <- enums do

      enum_name      = Module.concat(name)
      default        = make_enum_default(members)
      encode_members = make_encode_enum_members(members)
      decode_members = make_decode_enum_members(members)

      quote do
        defmodule unquote(enum_name) do
          @moduledoc false

          unquote(default)

          unquote(encode_members)
          def encode(x), do: x

          unquote(decode_members)
          def decode(x), do: x

          def members(), do: unquote(members)
        end
      end

    end

    ++ # concat enumerations and messages definitions

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


          @spec defs() :: struct
          def defs(), do: unquote(fields_map)

        end # module
      end
    end # for

  end


  # -- Enum


  defp make_enum_default(members) do
    {_, default} = Enum.find(members, fn {x, _} -> x == 0 end)
    quote do
      def default(), do: unquote(default)
    end
  end


  defp make_encode_enum_members(members) do
    for {value, member} <- members do
      quote do
        def encode(unquote(member)), do: unquote(value)
      end
    end
  end


  defp make_decode_enum_members(members) do
    for {value, member} <- members do
      quote do
        def decode(unquote(value)), do: unquote(member)
      end
    end
  end


  # Generate fields of the struct which is create for a message.
  defp make_struct_fields(fields) do
    for {_, _, name, kind, _} <- fields do
      case kind do
        :map               -> {name, Macro.escape(%{})}
        {:oneof, parent}   -> {parent, nil}
        {:repeated, _}     -> {name, []}
        {:normal, default} -> {name, default}
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
          {:map, {key_type, {:message, msg}}} ->
            {
              key_type,
              {:message, msg |> elem(2) |> Module.concat()}
            }


          {:map, {key_type, {:enum, {_, _, enum}}}} ->
            {
              key_type,
              {:enum, Module.concat(enum)}
            }

          {_, {:enum, {_, _, enum}}} ->
            {:enum, Module.concat(enum)}

          {_, {:message, msg}} ->
            {:message, msg |> elem(2) |> Module.concat()}

          {_, ty} ->
            ty
        end
        Map.put(acc, tag, {name, kind, ty})
      end)
    |> Macro.escape()
  end

end
