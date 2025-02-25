[
  inputs: ["mix.exs", "{config,lib,test,conformance,benchmark}/**/*.{ex,exs}"],
  plugins: [Quokka],
  quokka: [
    only: [:line_length]
  ]
]
