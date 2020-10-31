defmodule Protox.Mixfile do
  use Mix.Project

  def project do
    [
      app: :protox,
      version: "1.2.0",
      elixir: "~> 1.7",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      elixirc_paths: elixirc_paths(Mix.env()),
      escript: escript(),
      name: "Protox",
      source_url: "https://github.com/ahamez/protox",
      description: description(),
      package: package(),
      dialyzer: [plt_file: {:no_warn, "priv/plts/dialyzer.plt"}],
      docs: docs()
    ]
  end

  # Do not compile conformance and benchmarks related files when in production
  defp elixirc_paths(:prod), do: ["lib"]
  defp elixirc_paths(_), do: ["lib", "conformance", "benchmarks"]

  def application do
    [
      extra_applications: [
        :crypto,
        :mix
      ]
    ]
  end

  defp deps do
    [
      {:benchee, "~> 1.0", only: [:dev], runtime: false},
      {:benchee_html, "~> 1.0", only: [:dev], runtime: false},
      {:benchee_markdown, "~> 0.2", only: [:dev], runtime: false},
      {:credo, "~> 1.4", only: [:test, :dev], runtime: false},
      {:dialyxir, "~> 1.0", only: [:test, :dev], runtime: false},
      {:excoveralls, "~> 0.13", only: [:test], runtime: false},
      {:ex_doc, "~> 0.22", only: [:dev], runtime: false},
      {:git_hooks, "~> 0.5", only: [:test, :dev], runtime: false},
      {:inch_ex, "~> 2.0.0", only: [:docs], runtime: false},
      {:propcheck, "~> 1.2", only: [:test, :dev]}
    ]
  end

  defp description do
    """
    A fast, easy to use and 100% conformant Elixir library for Google Protocol Buffers (aka protobuf)
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
      links: %{"GitHub" => "https://github.com/ahamez/protox"}
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md", "documentation/reference.md"]
    ]
  end
end
