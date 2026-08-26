defmodule Protox.ConformanceTest do
  use ExUnit.Case, async: false

  alias Mix.Tasks.Protox.Conformance

  @tag :conformance
  test "Launch conformance" do
    {:ok, _removed_files} = File.rm_rf("./failing_tests.txt")

    assert {:ok, _compile_only_result} = Conformance.run(["--quiet", "--compile-only"])

    # {:ok, _} here just means that the runner could be launched, not that the conformance
    # test performed correctly. We'll check the absence of the "failing_tests.txt" file
    # to verify this.
    assert {:ok, _run_result} = Conformance.run(["--quiet"])

    # protobuf conformance runner produces this file only when some tests have failed
    refute File.exists?("./failing_tests.txt"),
           "Please check 'failing_tests.txt' file and 'conformance_report' directory for more information about this failure"
  end
end
