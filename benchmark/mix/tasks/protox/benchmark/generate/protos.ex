defmodule Mix.Tasks.Protox.Benchmark.Generate.Protos do
  @moduledoc false

  use Mix.Task

  require Logger

  # Frequencies are taken from
  # https://github.com/protocolbuffers/protobuf/blob/336d6f04e94efebcefb5574d0c8d487bcb0d187e/benchmarks/gen_synthetic_protos.py.
  @field_freqs [
    {"bool", "", 8.321},
    {"bool", "repeated", 0.033},
    {"bytes", "", 0.809},
    {"bytes", "repeated", 0.065},
    {"double", "", 2.845},
    {"double", "repeated", 0.143},
    {"fixed32", "", 0.084},
    {"fixed32", "repeated", 0.012},
    {"fixed64", "", 0.204},
    {"fixed64", "repeated", 0.027},
    {"float", "", 2.355},
    {"float", "repeated", 0.132},
    {"int32", "", 6.717},
    {"int32", "repeated", 0.366},
    {"int64", "", 9.678},
    {"int64", "repeated", 0.425},
    {"sfixed32", "", 0.018},
    {"sfixed32", "repeated", 0.005},
    {"sfixed64", "", 0.022},
    {"sfixed64", "repeated", 0.005},
    {"sint32", "", 0.026},
    {"sint32", "repeated", 0.009},
    {"sint64", "", 0.018},
    {"sint64", "repeated", 0.006},
    {"string", "", 25.461},
    {"string", "repeated", 2.606},
    {"Enum", "", 6.16},
    {"Enum", "repeated", 0.576},
    {"Message", "", 22.472},
    {"Message", "repeated", 7.766},
    {"uint32", "", 1.289},
    {"uint32", "repeated", 0.051},
    {"uint64", "", 1.044},
    {"uint64", "repeated", 0.079}
  ]

  @message_template """
  syntax = "proto3";
  package protox.benchmark.synthetic_<%= count %>;

  enum Enum {
    ZERO = 0;
  }

  message Message {
  <%= for {type, label, counter} <- fields do %>
    <%= label %> <%= type %> field_<%= counter %> = <%= counter %>;<% end %>
  }
  """

  @impl Mix.Task
  @spec run(any) :: any
  def run(_args) do
    for count <- [5, 10, 20, 50, 100] do
      Logger.info("Generating synthetic proto with #{count} fields")
      content = EEx.eval_string(@message_template, count: count, fields: random_choices(count))
      File.write!("./protos/benchmark/synthetic_#{count}.proto", content)
    end
  end

  defp random_choices(count) when count >= 0 do
    total_weight =
      @field_freqs
      |> Stream.map(fn {_, _, freq} -> freq end)
      |> Enum.sum()

    cumulative_weights =
      @field_freqs
      |> Stream.map(fn {_, _, freq} -> freq end)
      |> Enum.scan(&(&1 + &2))

    Enum.map(1..count, fn c ->
      rand = :rand.uniform() * total_weight
      index = Enum.find_index(cumulative_weights, &(rand <= &1))
      {type, label, _freq} = Enum.at(@field_freqs, index)
      {type, label, c}
    end)
  end
end
