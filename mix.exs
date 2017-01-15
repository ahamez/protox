defmodule Protox.Mixfile do

  use Mix.Project


  def project do
    [
      app: :protox,
      version: "0.12.1",
      elixir: "~> 1.3",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      escript: [main_module: Protox.Escript.Main],
      name: "Protox",
      source_url: "https://github.com/ahamez/protox",
      description: description(),
      package: package(),
    ]
  end


  def application do
    [
      applications: []
    ]
  end


  defp deps do
    [
      {:credo, "~> 0.5", only: [:dev]},
      {:dialyxir, "~> 0.4", only: [:dev], runtime: false},
      {:ex_doc, "~> 0.14", only: [:dev]},
      {:excoveralls, "~> 0.5", only: :test},
      {:inch_ex,  "~> 0.5.5", only: :docs},
      {:varint, "~> 1.1.0"},
    ]
  end


  defp description do
    """
    A library for Protocol Buffers
    """
  end


  defp package do
    [
      name: :protox,
      files: ["lib", "mix.exs", "README*", "LICENSE"],
      maintainers: ["Alexandre Hamez"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/ahamez/protox",}
    ]
  end

end
