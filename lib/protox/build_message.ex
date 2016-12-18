defmodule Protox.BuildMessage do

  defmacro __using__(messages: messages) do
    messages
    |> Enum.map(
      fn {{_, _, name}, fs} ->
        fields = for {_, _, f} <- fs, do: List.to_tuple(f)
        {name, fields}
      end)
    |> Protox.BuildMessage.build()
  end


  def build(messages) do

    for {name, fields} <- messages do

      msg_name      = Module.concat(name)
      struct_fields = make_struct_fields(fields)
      fields_map    = make_fields_map(fields)
      tags          = make_tags(fields)

      quote do
        defmodule unquote(msg_name) do
          @moduledoc false

          IO.puts "New module #{inspect __MODULE__}"

          defstruct unquote(struct_fields)

          @spec encode(struct) :: iolist
          def encode(msg = %unquote(msg_name){}) do
            Protox.Encode.encode(msg)
          end


          @spec encode_binary(struct) :: binary
          def encode_binary(msg = %unquote(msg_name){}) do
            Protox.Encode.encode_binary(msg)
          end


          @spec decode(binary) :: struct
          def decode(bytes) do
            Protox.Decode.decode(bytes, unquote(msg_name))
          end


          @spec defs() :: struct
          def defs() do
            %Protox.MessageDefinitions{
              fields: unquote(fields_map),
              tags: unquote(tags)
            }
          end

        end # module
      end
    end # for

  end


  # -- Private


  defp make_struct_fields(fields) do
    for {_tag, name, kind, type} <- fields do
      case kind do
        :map             -> {name, Macro.escape(%{})}
        {:oneof, parent} -> {parent, nil}
        {:repeated, _}   -> {name, []}
        :normal          ->
          case type do
            {:enum, [{_, first} | _]} -> {name, first}
            {:message, _}             -> {name, nil}
            _                         -> {name, Protox.Default.default(type)}
          end
      end
    end
  end


  defp make_fields_map(fields) do
    for {tag, name, kind, type} <- fields, into: %{} do
      ty = case {kind, type} do
        {:map, {key_type, {:message, msg}}} ->
          {
            key_type,
            %Protox.Message{name: msg |> elem(2) |> Module.concat()}
          }

        {_, {:enum, members}} ->
          %Protox.Enumeration{
            members: Map.new(members),
            values: (for {rank, atom} <- members, into: %{}, do: {atom, rank})
          }

        {_, {:message, msg}} ->
          %Protox.Message{name: msg |> elem(2) |> Module.concat()}

        {_, ty} ->
          ty
      end

      {tag, %Protox.Field{name: name, kind: kind, type: ty}}
    end
    |> Macro.escape()
  end


  defp make_tags(fields) do
    Enum.sort(for {tag, _, _, _} <- fields, do: tag)
  end

end
