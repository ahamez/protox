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
    Protox.DefineEnum.define(enums) ++ Protox.DefineMessage.define(messages)
  end
end
