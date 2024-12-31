defmodule Protox.Mixfile do
  use Mix.Project

  def project do
    [
      app: :protox,
      version: "2.0.0-dev",
      elixir: "~> 1.15",
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
      dialyzer: [plt_local_path: "priv/plts"],
      docs: docs(),
      preferred_cli_env: [muzak: :test]
    ]
  end

  # Do not compile conformance and benchmarks related files when in production
  defp elixirc_paths(:prod), do: ["lib"]
  defp elixirc_paths(_), do: ["lib", "conformance", "benchmarks", "test/support"]

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
      {:castore, "~> 1.0", only: :test},
      {:credo, "~> 1.4", only: [:test, :dev], runtime: false},
      {:decimal, "~> 2.0"},
      {:dialyxir, "~> 1.0", only: [:test, :dev], runtime: false},
      {:excoveralls, "~> 0.13", only: [:test], runtime: false},
      {:ex_doc, "~> 0.22", only: [:dev], runtime: false},
      {:jason, "~> 1.2", optional: true},
      {:poison, "~> 4.0 or ~> 5.0 or ~> 6.0", optional: true},
      {:propcheck, github: "alfert/propcheck", ref: "c564e89d", only: [:test, :dev]}
    ]
    |> maybe_add_muzak_pro()
    |> maybe_download_protobuf()
  end

  defp maybe_add_muzak_pro(deps) do
    case System.get_env("PROTOX_MUZAK_PRO_CREDS") do
      nil ->
        deps

      creds ->
        muzak_pro =
          {:muzak,
           git: "https://#{creds}@git.devonestes.com/muzak/muzak.git", tag: "1.1.0", only: [:test]}

        [muzak_pro | deps]
    end
  end

  defp maybe_download_protobuf(deps) do
    case System.get_env("PROTOX_PROTOBUF_VERSION") do
      nil ->
        deps

      version ->
        protobuf =
          {:protobuf,
           github: "protocolbuffers/protobuf",
           tag: "v#{version}",
           submodules: true,
           app: false,
           compile: false,
           only: [:dev, :test]}

        [protobuf | deps]
    end
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
      links: %{"GitHub" => "https://github.com/ahamez/protox"},
      exclude_patterns: [".DS_Store"]
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md", "documentation/reference.md"]
    ]
  end
end
