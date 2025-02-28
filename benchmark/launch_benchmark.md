# Protox Benchmark

All the following commands are executed from the root of the project.

## Launch the benchmark

- you can specify the task to run (`encode` or `decode`)
- you have to specify the benchmark tag, which will be used to identify the benchmark run
- benchmark results are stored in `./benchmark/output/benchee/<TASK>-<DATE>-<BENCHMARK_TAG>`

```
mix protox.benchmark.run [--task <TASK>] <BENCHMARK_TAG>
```

Example:

```
mix protox.benchmark.run --task decode my_tag
```


## Aggregate the results

```
mix protox.benchmark.report <BENCHMARK_RESULT_PATHS>
```

Example:

```
mix protox.benchmark.report ./benchmark/output/benchee/encode-*
```
