Benchee.run(
  %{},
  formatters: [
    {Benchee.Formatters.HTML, file: "./benchmarks/output/decode.html"},
    {Benchee.Formatters.Markdown, file: "./benchmarks/output/decode.md"}
  ],
  load: ["./benchmarks/*decode*.benchee"]
)

Benchee.run(
  %{},
  formatters: [
    {Benchee.Formatters.HTML, file: "./benchmarks/output/encode.html"},
    {Benchee.Formatters.Markdown, file: "./benchmarks/output/encode.md"}
  ],
  load: ["./benchmarks/*encode*.benchee"]
)
