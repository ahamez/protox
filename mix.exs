defmodule Protox.Mixfile do
  use Mix.Project

  def project do
    [
      app: :protox,
      version: "0.19.1",
      elixir: "~> 1.4",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      escript: [main_module: Protox.Escript.Main],
      name: "Protox",
      source_url: "https://github.com/EasyMile/protox",
      description: description(),
      package: package()
    ]
  end

  def application do
    [
      applications: []
    ]
  end

  defp deps do
    [
      {:credo, "~> 1.4", only: [:dev]},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:excoveralls, "~> 0.12", only: :test},
      {:ex_doc, "~> 0.22", only: [:dev]},
      {:inch_ex, "~> 2.0.0", only: :docs},
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
      links: %{"GitHub" => "https://github.com/EasyMile/protox"}
    ]
  end
end
