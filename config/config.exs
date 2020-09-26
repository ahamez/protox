use Mix.Config

# Configure git hooks
if Mix.env() != :prod do
  config :git_hooks,
    auto_install: true,
    verbose: true,
    hooks: [
      pre_commit: [
        tasks: [
          {:cmd, "mix format"}
        ]
      ],
      pre_push: [
        verbose: false,
        tasks: [
          {:cmd, "mix credo"},
          {:cmd, "mix dialyzer"},
          {:cmd, "mix test"}
        ]
      ]
    ]
end
