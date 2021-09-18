defmodule Protox.ConformanceTest do
  use ExUnit.Case

  @tag :conformance
  test "Launch conformance" do
    {:ok, _} = File.rm_rf("./failing_tests.txt")

    runner = System.get_env("PROTOBUF_CONFORMANCE_RUNNER")
    assert runner != nil, "PROTOBUF_CONFORMANCE_RUNNER not set"

    assert File.exists?(runner)

    # {:ok, _} here just means that the runner could be launched, not that the conformance
    # test performed correctly. We'll check the absence of the "failing_tests.txt" file
    # to verify this.
    assert {:ok, _} = Mix.Tasks.Protox.Conformance.run(["--runner=#{runner}", "--quiet"])

    # protobuf conformance runner produces this file only when some tests have failed
    refute File.exists?("./failing_tests.txt"),
           "Please check 'failing_tests.txt' file and 'conformance_report' directory for more information about this failure"
  end
end
