defmodule Mix.Tasks.Protox.Benchmark.Run do
  @moduledoc false

  use Mix.Task

  alias Benchee.Formatters.Console

  @options [
    task: :string,
    warmup: :integer,
    time: :integer,
    memory_time: :integer,
    reduction_time: :integer,
    input: :string,
    profile_after: :string,
    profile_type: :string,
    profile_scope: :string
  ]

  @profile_types ~w(time memory calls)a
  @profile_scopes ~w(module codec all)a

  # The modules a `--profile-scope codec` pass traces. Scoping is not just a filter: tprof
  # accumulates the cost of an *untraced* callee into its nearest traced caller, so this list
  # is what decides whether `Protox.Varint.encode/1` shows up on its own line or inside the
  # generated field encoder that called it.
  @codec_modules [Protox.Decode, Protox.Encode, Protox.Varint, Protox.String, Protox.Zigzag]

  @impl Mix.Task
  @spec run(any) :: any
  def run(args) do
    with {opts, argv, []} <- OptionParser.parse(args, strict: @options),
         {:ok, tasks} <- get_tasks(opts),
         {:ok, profile} <- get_profile(opts),
         {:ok, tag} <- get_tag(argv, profile),
         payloads = get_payloads("./benchmark/benchmark_payloads.bin"),
         {:ok, payloads} <- select_inputs(payloads, opts) do
      verify_payloads(payloads)

      Enum.each(tasks, fn task ->
        run_benchee(task, payloads, tag, profile, get_benchee_config(opts))
      end)
    else
      err ->
        Mix.shell().error("Error: #{inspect(err)}")
        exit({:shutdown, 1})
    end
  end

  defp measure_job(:encode), do: %{encode: fn {module, msgs} -> Enum.each(msgs, &module.encode!/1) end}
  defp measure_job(:decode), do: %{decode: fn {module, binaries} -> Enum.each(binaries, &module.decode!/1) end}

  # Arity-0 twins of the measurement jobs: the profile mode closes over one input's samples
  # instead of receiving them from Benchee, so the input name can live in the job name.
  defp profile_job(:encode, module, msgs), do: fn -> Enum.each(msgs, &module.encode!/1) end
  defp profile_job(:decode, module, binaries), do: fn -> Enum.each(binaries, &module.decode!/1) end

  # Benchee keeps the order of a list of inputs (a map would be reordered by term
  # order), so sorting by corpus size makes the report read smallest to largest.
  defp build_inputs(payloads, task) do
    payloads
    |> sort_by_size()
    |> Enum.map(fn {name, {module, samples}} -> {name, {module, inputs_for(samples, task)}} end)
  end

  defp sort_by_size(payloads) do
    Enum.sort_by(payloads, fn {_name, {_module, samples}} -> total_size(samples) end)
  end

  defp inputs_for(samples, :encode), do: Enum.map(samples, fn {msg, _size, _bytes} -> msg end)
  defp inputs_for(samples, :decode), do: Enum.map(samples, fn {_msg, _size, bytes} -> bytes end)

  defp total_size(samples) do
    samples
    |> Stream.map(fn {_msg, size, _bytes} -> size end)
    |> Enum.sum()
  end

  # An optimization that silently drops fields would post excellent numbers, so the
  # corpus is re-encoded once, outside the measured region, and checked against the
  # sizes recorded when it was generated.
  #
  # Known limitation: this only catches size-changing corruption, and only on the
  # encoding side. Value-level correctness and the decoder are covered by `mix test`
  # and `mix protox.conformance`.
  defp verify_payloads(payloads) do
    Enum.each(payloads, fn {name, {module, samples}} ->
      Enum.each(samples, fn {msg, size, _bytes} -> verify_sample(name, module, msg, size) end)
    end)
  end

  defp verify_sample(name, module, msg, size) do
    {iodata, reported_size} = module.encode!(msg)
    encoded_size = IO.iodata_length(iodata)

    cond do
      encoded_size != size ->
        Mix.raise("#{name}: encoded #{encoded_size} bytes, corpus expects #{size}")

      reported_size != size ->
        Mix.raise("#{name}: encode! reported #{reported_size} bytes, corpus expects #{size}")

      true ->
        :ok
    end
  end

  defp run_benchee(task, payloads, tag, nil = _profile, benchee_cfg) do
    Benchee.run(
      measure_job(task),
      inputs: build_inputs(payloads, task),
      save: [
        path: Path.join(["./benchmark/output/benchee", "#{task}-#{tag}.benchee"]),
        tag: "#{task}-#{tag}"
      ],
      warmup: benchee_cfg.warmup,
      time: benchee_cfg.time,
      memory_time: benchee_cfg.memory_time,
      reduction_time: benchee_cfg.reduction_time,
      formatters: [Console]
    )
  end

  # Profiling is a mode of its own, not a flag on a measurement run: all four durations are
  # zero (Benchee skips every measurement phase and prints no statistics), there is no `save:`
  # so profile runs never land in ./benchmark/output/benchee, and the formatters are off.
  # Benchee's profiler runs the scenario function exactly once, after everything else.
  defp run_benchee(task, payloads, _tag, profile, _benchee_cfg) do
    Benchee.run(
      profile_jobs(payloads, task),
      warmup: 0,
      time: 0,
      memory_time: 0,
      reduction_time: 0,
      formatters: [],
      print: [configuration: false, benchmarking: false],
      profile_after: {profile.profiler, profiler_opts(profile, payloads)}
    )
  end

  # Benchee's profiling banner prints the *job* name and nothing else, so with `inputs:` every
  # section would be labelled identically. Passing no inputs and folding the input name into
  # the job name instead makes each section self-identifying. The rank is zero-padded because
  # Benchee reduces over the jobs map in term order, which would otherwise put synthetic_200
  # before synthetic_5 and lose the smallest-to-largest reading order.
  defp profile_jobs(payloads, task) do
    payloads
    |> sort_by_size()
    |> Enum.with_index(1)
    |> Map.new(fn {{name, {module, samples}}, rank} ->
      rank = String.pad_leading(Integer.to_string(rank), 2, "0")

      {"#{task} #{rank} #{name}", profile_job(task, module, inputs_for(samples, task))}
    end)
  end

  defp profiler_opts(%{profiler: :tprof} = profile, payloads) do
    [type: profile.type, report: :total] ++
      matching(profile.scope, payloads) ++ threshold(profile.type)
  end

  defp profiler_opts(_other_profiler, _payloads), do: []

  defp matching(:all, _payloads), do: []
  defp matching(:codec, _payloads), do: [matching: Enum.map(@codec_modules, &{&1, :_, :_})]

  defp matching(:module, payloads) do
    modules =
      payloads
      |> Enum.map(fn {_name, {module, _samples}} -> module end)
      |> Enum.uniq()

    [matching: Enum.map(modules, &{&1, :_, :_})]
  end

  # Drop the rows that contribute nothing: most fields of a wide message hold their default
  # and neither allocate nor get called. tprof rejects a threshold that doesn't match its type.
  defp threshold(:memory), do: [memory: 1]
  defp threshold(:calls), do: [calls: 2]
  defp threshold(:time), do: [time: 1]

  defp get_tasks(opts) do
    case Keyword.get(opts, :task) do
      nil -> {:ok, [:encode, :decode]}
      "encode" -> {:ok, [:encode]}
      "decode" -> {:ok, [:decode]}
      other -> {:error, ~s(Unknown task #{inspect(other)}, expected "encode" or "decode")}
    end
  end

  defp select_inputs(payloads, opts) do
    case Keyword.get(opts, :input) do
      nil ->
        {:ok, payloads}

      names ->
        names = String.split(names, ",", trim: true)

        case Enum.reject(names, &Map.has_key?(payloads, &1)) do
          [] -> {:ok, Map.take(payloads, names)}
          unknown -> {:error, "Unknown input(s) #{inspect(unknown)}, have #{inspect(Map.keys(payloads))}"}
        end
    end
  end

  # Validated here rather than left to Benchee: an unknown profiler raises only *after* the
  # whole run and every formatter has finished, and a type/threshold mismatch raises from
  # inside the profiling loop.
  defp get_profile(opts) do
    case Keyword.get(opts, :profile_after) do
      nil -> no_profile(opts)
      name -> build_profile(name, opts)
    end
  end

  defp no_profile(opts) do
    case Keyword.take(opts, [:profile_type, :profile_scope]) do
      [] -> {:ok, nil}
      given -> {:error, "#{inspect(Keyword.keys(given))} requires --profile-after"}
    end
  end

  defp build_profile(name, opts) do
    with {:ok, profiler} <- get_profiler(name),
         {:ok, type} <- get_profile_type(profiler, opts),
         {:ok, scope} <- get_profile_scope(opts) do
      {:ok, %{profiler: profiler, type: type, scope: scope}}
    end
  end

  defp get_profiler(name) do
    supported = Benchee.Profile.builtin_profilers()

    case Enum.find(supported, &(Atom.to_string(&1) == name)) do
      nil -> {:error, "Unknown profiler #{inspect(name)}, expected one of #{inspect(supported)}"}
      profiler -> {:ok, profiler}
    end
  end

  defp get_profile_type(:tprof, opts), do: get_enum_opt(opts, :profile_type, @profile_types, :memory)

  defp get_profile_type(profiler, opts) do
    case Keyword.fetch(opts, :profile_type) do
      :error -> {:ok, nil}
      {:ok, _type} -> {:error, "--profile-type only applies to tprof, not #{inspect(profiler)}"}
    end
  end

  defp get_profile_scope(opts), do: get_enum_opt(opts, :profile_scope, @profile_scopes, :module)

  defp get_enum_opt(opts, key, allowed, default) do
    case Keyword.fetch(opts, key) do
      :error ->
        {:ok, default}

      {:ok, value} ->
        case Enum.find(allowed, &(Atom.to_string(&1) == value)) do
          nil -> {:error, "Unknown --#{dasherize(key)} #{inspect(value)}, expected one of #{inspect(allowed)}"}
          found -> {:ok, found}
        end
    end
  end

  defp dasherize(key) do
    key
    |> Atom.to_string()
    |> String.replace("_", "-")
  end

  defp get_benchee_config(opts) do
    %{
      warmup: Keyword.get(opts, :warmup, 2),
      time: Keyword.get(opts, :time, 5),
      memory_time: Keyword.get(opts, :memory_time, 2),
      reduction_time: Keyword.get(opts, :reduction_time, 2)
    }
  end

  # A profile run saves nothing, so it has no use for a tag.
  defp get_tag([], nil = _profile), do: {:error, "No tag provided"}
  defp get_tag([], _profile), do: {:ok, nil}

  defp get_tag([tag], _profile) do
    timestamp = Calendar.strftime(DateTime.utc_now(), "%H%M%S")

    {:ok, "#{timestamp}-#{tag}"}
  end

  defp get_tag([_tag | _rest], _profile), do: {:error, "Too many tags provided"}

  def get_payloads(path) do
    path
    |> File.read!()
    |> :erlang.binary_to_term()
  end
end
