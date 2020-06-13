Benchee.run(
  %{},
  formatters: [
    {Benchee.Formatters.HTML, file: "./benchmarks/output/decode.html"}
  ],
  load: ["./benchmarks/decode*.benchee"]
)

Benchee.run(
  %{},
  formatters: [
    {Benchee.Formatters.HTML, file: "./benchmarks/output/encode.html"}
  ],
  load: ["./benchmarks/encode*.benchee"]
)
