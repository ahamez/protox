defmodule Protox.Mixfile do

  use Mix.Project

  def project do
    [
      app: :protox,
      version: "0.1.0",
      elixir: "~> 1.3",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
    ]
  end

  def application do
    [
      applications: []
    ]
  end

  defp deps do
    [
      {:credo, "~> 0.5.3"},
      {:dialyxir, "~> 0.4", only: [:dev], runtime: false},
      {:excoveralls, "~> 0.5", only: :test},
      {:varint, "~> 1.0"},
    ]
  end

end
