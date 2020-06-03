defmodule Protox.Mixfile do
  use Mix.Project

  def project do
    [
      app: :protox,
      version: "0.20.0",
      elixir: "~> 1.6",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      elixirc_paths: elixirc_paths(Mix.env()),
      escript: escript(),
      name: "Protox",
      source_url: "https://github.com/EasyMile/protox",
      description: description(),
      package: package(),
      dialyzer: [plt_file: {:no_warn, "priv/plts/dialyzer.plt"}]
    ]
  end

  # Do not compile conformance related files when in production
  defp elixirc_paths(:prod), do: ["lib"]
  defp elixirc_paths(_), do: ["lib", "conformance"]

  def application do
    [extra_applications: [:mix]]
  end

  defp deps do
    [
      {:credo, "~> 1.4", only: [:dev]},
      {:dialyxir, "~> 1.0", only: [:test, :dev], runtime: false},
      {:excoveralls, "~> 0.12", only: :test},
      {:ex_doc, "~> 0.22", only: [:dev]},
      {:inch_ex, "~> 2.0.0", only: :docs},
      {:propcheck, "~> 1.2", only: [:test, :dev]}
    ]
  end

  defp description do
    """
    A 100% conformant Elixir library for Protocol Buffers
    """
  end

  def escript do
    [
      # do not start any application: avoid propcheck app to fail when running escript
      app: nil,
      main_module: Protox.Conformance.Escript,
      name: "protox_conformance"
    ]
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
