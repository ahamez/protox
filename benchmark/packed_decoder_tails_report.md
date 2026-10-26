# Packed fixed-width decoder tails

Date: 2026-10-26. Baseline: `ffbde135dd3db17abb61c1e235a55b5b095fd491`.
Candidate branch: `codex/packed-decoder-tails`.

## Change and complexity

The patch adds one direct single-element binary pattern clause to each of
`parse_repeated_fixed32/2`, `parse_repeated_fixed64/2`,
`parse_repeated_sfixed32/2`, and `parse_repeated_sfixed64/2`.
The four-element clauses retain priority. Empty input and malformed-input
fallbacks retain their existing behavior. Float and double paths are unchanged.

Production change: **16 added lines**, including blank lines. No new function,
module, macro, dependency, public API, or cross-layer call. Time remains O(n),
with a reversed list accumulator and the existing four-element unroll.
The four short clauses repeat an existing signedness/width distinction rather
than adding a generator or abstraction. The maintenance cost is low: future
changes to fixed-width decoding must keep the chunk and tail patterns aligned.
The fallback helper calls remain to preserve their exact error payloads/messages.

The intended benefit is fewer temporary tuples and binary views when a packed
run ends with one to three elements after its four-element chunks. A run whose
length is divisible by four has no such tail and serves as a control.

## Correctness and checks

The expanded tests cover all four integer types, zero through nine elements,
signed/unsigned limits, nonempty accumulators, ordering, and every possible
truncated tail length after zero through nine valid elements. Truncated input
must produce the same complete `Protox.DecodingError` struct (including binary
and message), not just the same exception type. These tests passed before and
after the optimization; this is a performance change, not a behavior bug.

All required local checks pass: `mix compile --warnings-as-errors`,
`mix format --check-formatted`, `mix credo`, `mix dialyzer`, and `mix test`.
The full suite reports **282 passed** (7 doctests, 8 properties, 267 tests),
with 1 conformance test excluded. Focused checks report 15 passed on both
baseline and candidate. The optional conformance runner was not executed.

## Benchmark method

Hardware: Apple M1 Pro. OS: macOS 27.0.1. Runtime: Elixir 1.20.4,
Erlang/OTP 29 (ERTS 17.1.1), JIT enabled. Benchmarks use `ERL_FLAGS='+S 1:1'`
so each VM has one scheduler. Results describe this machine/runtime only.

The existing frozen 16-input Protox corpus was used without regeneration:

- SHA256: `75fadc84eb8be23f4e2466d277d2a31ca547b63efe480af634932930ad3b2e53`
- Size: 2,845,788 bytes.

The repository benchmark task performs its normal corpus encoding-size sanity
check before timing. A separate full decoded-value parity check swaps the
baseline/candidate `Protox.Decode` modules in memory and compares generated
decoders on all **160 samples across 16 inputs**; all values match. The benchmark
task measures full generated-message decoding across each input's sample set,
not just calls to the four modified helpers.

Three paired rounds use order baseline/candidate, candidate/baseline,
baseline/candidate. Each variant compiles before its separate benchmark VM.
The command is:

```sh
ERL_FLAGS='+S 1:1' mix protox.benchmark.run --task decode \
  --warmup 1 --time 1 --memory-time 1 --reduction-time 1 tail-baseline-r1
```

Each scenario's reported time is the median of its three per-run Benchee mean
times. Memory and reductions are also aggregated from the three runs. Timing
is exploratory: this is a shared desktop with no CPU affinity or frequency
locking, and three short runs do not establish a statistical confidence interval.

A separate targeted Benchee harness runs 1,000 helper calls per operation for
`fixed32` and `fixed64` with 1, 3, 4, and 9 elements. It loads an unchanged,
renamed baseline module next to the candidate in the same VM. Both jobs use
the same dispatch and batching overhead. Divide batch allocation by 1,000 for
per-call figures; timing includes batching/dispatch overhead. These numbers
are microbenchmarks, not end-to-end message throughput.

## Results

### Full-message Protox task

Only `test_all_types_proto3` changes allocation/reductions, identically in all
three runs of each variant:

| Metric per 10-message corpus batch | Baseline | Candidate | Reduction |
| --- | ---: | ---: | ---: |
| Allocated bytes | 681,248 | 671,800 | 1.39% |
| Reductions | 12,375 | 11,992 | 3.09% |

All other 15 inputs have exactly unchanged allocation and reduction counts in
the saved statistics. Their timing changes therefore help show measurement
noise. Time below is microseconds per input's 10-message corpus batch, with
negative change meaning less time. The paired range is the minimum and maximum
candidate/baseline mean-time change across the three paired rounds; it is not a
confidence interval.

| Input | Baseline median mean (µs) | Candidate median mean (µs) | Change | Paired change range |
| --- | ---: | ---: | ---: | ---: |
| synthetic_5 | 4.31 | 4.35 | +0.9% | -5.3% to +3.2% |
| synthetic_10 | 16.76 | 17.27 | +3.0% | -10.2% to +4.6% |
| google_message1_proto3 | 16.17 | 16.50 | +2.1% | -0.1% to +2.2% |
| google_message1_proto2 | 16.54 | 16.80 | +1.6% | +0.3% to +1.7% |
| synthetic_20 | 63.92 | 65.34 | +2.2% | -4.6% to +3.0% |
| edge_special_floats | 59.61 | 59.19 | -0.7% | -3.1% to +1.5% |
| edge_negative_varints | 207.47 | 207.88 | +0.2% | -0.8% to +0.6% |
| test_all_types_proto3 | 277.75 | 275.44 | -0.8% | -6.3% to +14.2% |
| synthetic_50 | 597.71 | 601.28 | +0.6% | -3.9% to +6.2% |
| maps | 512.31 | 509.75 | -0.5% | -1.9% to +4.4% |
| edge_unicode_strings | 498.21 | 494.16 | -0.8% | -2.1% to +1.0% |
| prometheus_write_request | 1533.47 | 1499.15 | -2.2% | -2.9% to +1.0% |
| synthetic_100 | 2920.07 | 2824.50 | -3.3% | -4.6% to +6.0% |
| otel_traces_data | 969.25 | 965.42 | -0.4% | -2.6% to +2.9% |
| synthetic_100_edge | 6721.30 | 6670.50 | -0.8% | -1.7% to +1.8% |
| synthetic_200 | 30009.67 | 29568.69 | -1.5% | -3.8% to +1.0% |

The affected input's median changes by -0.8%, while paired runs
range from -6.3% to +14.2%.
That does **not establish a full-message throughput improvement**. Several
unaffected controls move by comparable amounts. The one-minute host load average at run
starts ranges from 4.76 to 9.21; no CPU-heavy agent checks ran alongside measurements,
but ordinary desktop activity was not isolated.

### Targeted packed-tail comparison

Each operation performs 1,000 decodes. Allocation columns are bytes per batch
and include a shared 64-byte batch overhead. The savings column divides the
baseline/candidate allocation difference by 1,000. Timing is mean µs per batch
from one targeted suite and includes shared loop/dispatch overhead.

| Input (type/elements) | Baseline bytes/batch | Candidate bytes/batch | Bytes saved/call | Baseline µs/batch | Candidate µs/batch |
| --- | ---: | ---: | ---: | ---: | ---: |
| fixed32/1 | 136,064 | 56,064 | 80 | 42.37 | 29.27 |
| fixed32/3 | 384,064 | 88,064 | 296 | 82.59 | 34.01 |
| fixed32/4 | 104,064 | 104,064 | 0 | 30.77 | 30.97 |
| fixed32/9 | 264,064 | 184,064 | 80 | 55.27 | 41.03 |
| fixed64/1 | 136,064 | 56,064 | 80 | 43.09 | 28.94 |
| fixed64/3 | 392,064 | 88,064 | 304 | 83.26 | 37.99 |
| fixed64/4 | 104,064 | 104,064 | 0 | 32.74 | 33.80 |
| fixed64/9 | 264,064 | 184,064 | 80 | 60.26 | 43.32 |

The tail cases save 80–304 bytes per call. Four-element controls allocate
exactly the same amount. Mean targeted tail timings decrease about 26–59%,
with the four-element controls changing by about +0.6% and +3.2%. These are
local microbenchmark observations; individual timing standard deviations are
11–70%, so they should not be presented as production speedup estimates.

### Complexity assessment and recommendation

The allocation saving is repeatable and the implementation cost is small:
four explicit clauses, 16 production lines, and stronger existing tests.
`Protox.Decode`'s on-disk BEAM grows from 223,612 to 225,132 bytes (+1,520,
**0.68%**). This measures the complete BEAM artifact including metadata/debug
information, not just executable instructions. No asymptotic complexity or
layering changes are introduced.

**I consider the trade-off favorable for a small allocation-focused merge.**
The benefit is strongest for workloads with many packed fixed-width integer
runs whose lengths are not multiples of four. On this corpus it saves 1.39%
of allocation in one input and leaves the other 15 unchanged. A requirement
for demonstrated general throughput improvement would not be met by these
measurements. No broader decoder rewrite is needed for this patch.

## Reproduction and raw artifacts

Local raw artifacts and runnable scripts are in `benchmark/output/tail_clauses/`
(ignored by Git), alongside the saved results in `benchmark/output/benchee/`.
The worktree retains them for review:

- `run_corpus.py`: interleaved existing-task runs, restores candidate source in a
  `finally` block.
- `baseline.ex.txt` / `candidate.ex.txt`: exact decoder sources used.
- `tail-{baseline,candidate}-r{1,2,3}.log`: full console output and host load at
  each run's start.
- `targeted.exs` / `targeted.log`: batched helper comparison.
- `parity.exs` / `parity.log`: full decoded-value parity of all 160 corpus samples.
- `exact-results.json`: unrounded means/allocation/reductions extracted directly
  from the saved Benchee suites; `summary.json` contains per-input medians.
- `beam-sizes.txt`: decoder BEAM artifact sizes for each run.
- Check logs: `setup.log`, `baseline-tests.log`, `candidate-tests.log`,
  `credo.log`, `dialyzer.log`, `tests.log`.

Run from the worktree root with dependencies installed and the above corpus
materialized (Git LFS). The benchmark driver expects the final candidate source
in `lib/protox/decode.ex` and the baseline Git revision available locally:

```sh
python3 benchmark/output/tail_clauses/run_corpus.py
ERL_FLAGS='+S 1:1' mix run --no-compile benchmark/output/tail_clauses/targeted.exs
```
