defmodule CodeGeneration.MixProject do
  use Mix.Project

  def project do
    [
      app: :code_generation,
      version: "0.1.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:protox, path: ".."},
      {:dialyxir, "~> 1.0", only: [:test, :dev], runtime: false},
      {:credo, "~> 1.4", only: [:test, :dev], runtime: false}
    ]
  end
end
