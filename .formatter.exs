[
  inputs: ["mix.exs", "{config,lib,test,conformance,benchmark}/**/*.{ex,exs}", "*.exs"],
  # Same as Credo setting.
  line_length: 120,
  plugins: [Quokka]
]
