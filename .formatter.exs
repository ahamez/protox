[
  inputs: ["mix.exs", "{config,lib,test,conformance,benchmark}/**/*.{ex,exs}", "*.exs"],
  # Same as Credo setting.
  line_length: 120,
  plugins: [Quokka],
  quokka: [
    files: %{
      # parse.ex manipulates runtime-generated Google.Protobuf.* modules alongside
      # compile-time Protox.Google.Protobuf.* descriptor modules with the same
      # basenames: Quokka's alias lifting shadows one with the other and silently
      # rebinds every bare reference to the wrong module.
      excluded: ["lib/protox/parse.ex"]
    }
  ]
]
