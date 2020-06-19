defmodule Protox.Debug do
  @moduledoc false

  def make_debug_fun(module_ast) do
    if Mix.env() in [:dev, :test] do
      str = Macro.to_string(module_ast)
      quote do: def(__generated_code__(), do: unquote(str))
    else
      quote do: []
    end
  end
end
