defmodule Protox.Define do
  @moduledoc false
  # Internal. Generates structs from message and enumeration definitions.

  defmacro __using__(opts) do
    {enums, opts} = Keyword.pop(opts, :enums)
    {messages, opts} = Keyword.pop(opts, :messages)

    define(
      %Protox.Definition{
        enums: enums |> Code.eval_quoted() |> elem(0),
        messages: messages |> Code.eval_quoted() |> elem(0)
      },
      opts
    )
  end

  def define(%Protox.Definition{} = definition, opts \\ []) do
    Protox.DefineEnum.define(definition.enums) ++
      Protox.DefineMessage.define(definition.messages, opts)
  end
end
