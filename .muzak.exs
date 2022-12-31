# Muzak uses different configuration profiles to allow you to use it in different ways (like
# in CI versus run locally by a developer). The `default` and `ci` profiles below should be
# a good starting point for most applications.
#
%{
  default: [
    # You can run your mutation tests in parallel in multiple independent BEAM nodes if you
    # like. This can offer some decrease in runtime, but the need for most applications this
    # will offer at most a 20% decrease in runtime and will be very difficult to set up
    # properly.
    nodes: 1,

    # You can customize which mutators you would like to use for your mutation testing here.
    # Some mutators often have a good deal of overlap in the types of issues that they might
    # find, so depending on the needs of your application you can include or exclude any
    # mutators here that you might like. Removing mutators will make for faster runtimes, but
    # at the cost of potentially lower coverage.
    #
    # If no config is set then all mutators are used.
    mutators: [
      Muzak.Mutators.Constants.Atoms,
      Muzak.Mutators.Constants.Booleans,
      Muzak.Mutators.Constants.Lists,
      Muzak.Mutators.Constants.Numbers,
      Muzak.Mutators.Constants.Strings,
      Muzak.Mutators.Conditionals.Boundary,
      Muzak.Mutators.Conditionals.Replace,
      Muzak.Mutators.Conditionals.Strict,
      Muzak.Mutators.Functions.Rename
    ],

    # Sometimes your test suite needs some sort of setup or reset before running, like if you
    # have seeds in a database that need to be reset before each test run or other sorts of
    # fixtures that need to be prepared. This configuration allows you to handle that sort of
    # setup or teardown so your test suite can run correctly for each mutation. This function
    # is executed
    before_suite: fn ->
      :ok
    end,

    # You can set at which percentage of coverage (or which percentage of mutations are caught
    # by your tests) you would like the run to be considered a failure. 100% is basically
    # impossible, but with some care and effort getting above 90% is definitely achievable.
    # For smaller sets of mutations the coverage percentage can typically be higher.
    min_coverage: 99,

    # To speed things up, you have the option of controlling which files, and which lines in
    # those files, will be mutated in any given run.
    #
    # The files passed to this function are the files in the `elixirc_paths` field in your
    # application configuration.
    #
    # This function must return a list of tuples, where the first element in the tuple is the
    # path to the file, and the second element is `nil` or a list of integers representing line
    # numbers.
    #
    #   - `{"path/to/file.ex", nil}` will make all possible mutations on all lines in the file.
    #   - `{"path/to/file.ex", [1, 2, 3]}` will make all possible mutations but only on lines
    #     1, 2 and 3 in the file.
    #
    mutation_filter: fn all_files ->
      all_files
      |> Enum.reject(&String.starts_with?(&1, "test/"))
      |> Enum.reject(&String.starts_with?(&1, "conformance/"))
      |> Enum.reject(&String.starts_with?(&1, "lib/mix/tasks/"))
      |> Enum.reject(fn file ->
        file in [
          # Protox Exceptions are always constructed with new/1,2
          "lib/protox/errors.ex",
          # Always end up with "equivalent mutants"
          "lib/protox/defs.ex",
          # Always end up with "equivalent mutants"
          "lib/protox/float.ex",
          # Always end up with string mutations that do not impact code
          "lib/protox/protoc.ex"
        ]
      end)
      |> Enum.filter(&String.ends_with?(&1, ".ex"))
      |> Enum.map(&{&1, nil})
    end,

    # If you would like to run fewer tests for each run, or run them in a certain order, you
    # can filter and order your test files here. Ordering your test files can lead to a
    # decrease in runtime, as each run ends at the first test failure.
    #
    test_file_filter: fn files ->
      files
    end
  ],
  ci: [
    nodes: 1,

    # Since there will be far fewer mutations in CI, the minimum coverage percentage can be
    # set higher.
    min_coverage: 90,

    # This will only mutate the lines that have changed since the last commit by a different
    # author. This will be an effective way to speed up execution and gradually introduce
    # mutation testing to the team's workflow, regardless of if the team is using merge
    # commits or not.
    #
    # This depends on `git` being available as a command on whichever system this task is
    # being run.
    #
    mutation_filter: fn _ ->
      {diff, 0} = System.cmd("git", ["diff", "HEAD~25"])

      # All of this is to parse the git diff output to get the correct files and line numbers
      # that have changed in the given diff since the last 25 commits.
      first = ~r|---\ (a/)?.*|
      second = ~r|\+\+\+\ (b\/)?(.*)|
      third = ~r|@@\ -[0-9]+(,[0-9]+)?\ \+([0-9]+)(,[0-9]+)?\ @@.*|
      fourth = ~r|^(\[[0-9;]+m)*([\ +-])|

      diff
      |> String.split("\n")
      |> Enum.reduce({nil, nil, %{}}, fn line, {current_file, current_line, acc} ->
        cond do
          String.match?(line, first) ->
            {current_file, current_line, acc}

          String.match?(line, second) ->
            current_file = second |> Regex.run(line) |> Enum.at(2)
            {current_file, nil, acc}

          String.match?(line, third) ->
            current_line = third |> Regex.run(line) |> Enum.at(2) |> String.to_integer()
            {current_file, current_line, acc}

          current_file == nil ->
            {current_file, current_line, acc}

          match?([_, _, "+"], Regex.run(fourth, line)) ->
            acc = Map.update(acc, current_file, [current_line], &[current_line | &1])
            {current_file, current_line + 1, acc}

          true ->
            {current_file, current_line, acc}
        end
      end)
      |> elem(2)
      |> Enum.reject(fn {file, _} -> String.starts_with?(file, "test/") end)
      |> Enum.filter(fn {file, _} -> String.ends_with?(file, ".ex") end)
    end,
    test_file_filter: fn files ->
      files
    end
  ]
}
