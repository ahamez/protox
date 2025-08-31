# Protox Benchmark

All the following commands are executed from the root of the project.

## Launch the benchmark

- you can specify the task to run (`encode` or `decode`)
- you can control run durations with flags (defaults shown below)
- you have to specify the benchmark tag, which will be used to identify the benchmark run
- benchmark results are stored in `./benchmark/output/benchee/<TASK>-<DATE>-<BENCHMARK_TAG>`

```
mix protox.benchmark.run [--task <TASK>] [--warmup 2] [--time 5] [--memory-time 2] [--reduction-time 2] <BENCHMARK_TAG>
```

Example:

```
# Short run (defaults)
mix protox.benchmark.run --task decode my_tag

# Longer run to reduce variance
mix protox.benchmark.run --task encode --warmup 3 --time 15 --memory-time 5 --reduction-time 5 my_long_tag
```


## Aggregate the results

```
mix protox.benchmark.report <BENCHMARK_RESULT_PATHS>
```

Example:

```
mix protox.benchmark.report ./benchmark/output/benchee/encode-*
```
