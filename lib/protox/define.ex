defmodule Protox.Define do
  @moduledoc false
  # Internal. Generates structs from message and enumeration definitions.

  defmacro __using__(opts) do
    {enums, opts} = Keyword.pop(opts, :enums)
    {messages, opts} = Keyword.pop(opts, :messages)

    define(
      enums |> Code.eval_quoted() |> elem(0),
      messages |> Code.eval_quoted() |> elem(0),
      opts
    )
  end

  def define(enums, messages, opts \\ []) do
    Protox.DefineEnum.define(enums) ++ Protox.DefineMessage.define(messages, opts)
  end
end
