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
    enums = Protox.DefineEnum.define(definition.enums)
    messages = Protox.DefineMessage.define(definition.messages, opts)

    quote do
      unquote_splicing(enums)
      unquote_splicing(messages)
    end
  end
end
