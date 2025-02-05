defmodule Protox.Define do
  @moduledoc false
  # Internal. Generates structs from message and enumeration definitions.

  defmacro __using__(opts) do
    {enums_schemas, opts} = Keyword.pop(opts, :enums_schemas)
    {messages_schemas, opts} = Keyword.pop(opts, :messages_schemas)

    define(
      %Protox.Definition{
        enums_schemas: enums_schemas |> Code.eval_quoted() |> elem(0),
        messages_schemas: messages_schemas |> Code.eval_quoted() |> elem(0)
      },
      opts
    )
  end

  def define(%Protox.Definition{} = definition, opts \\ []) do
    defined_enums = Protox.DefineEnum.define(definition.enums_schemas)
    defined_messages = Protox.DefineMessage.define(definition.messages_schemas, opts)

    quote do
      unquote_splicing(defined_enums)
      unquote_splicing(defined_messages)
    end
  end
end
