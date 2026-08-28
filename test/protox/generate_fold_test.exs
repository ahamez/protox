defmodule Protox.GenerateFoldTest do
  use ExUnit.Case, async: true

  import Protox.Generate, only: [fold_trivial_defs: 1]

  test "folds def and defp with a single-line body" do
    assert fold_trivial_defs("""
           def default() do
             {:ok, nil}
           end
           defp helper(x) do
             x + 1
           end
           """) == """
           def default(), do: {:ok, nil}
           defp helper(x), do: x + 1
           """
  end

  test "preserves surrounding lines and indentation" do
    assert fold_trivial_defs("""
           defmodule M do
             def f() do
               :ok
             end
           end
           """) == """
           defmodule M do
             def f(), do: :ok
           end
           """
  end

  test "does not fold bodies that open a block or use clause syntax" do
    for body <- ["case x do", "if x, do: y", "fn -> x end", ":ok # comment"] do
      code = "def f() do\n  #{body}\nend\n"
      assert fold_trivial_defs(code) == code
    end
  end

  test "does not fold multi-line bodies" do
    code = "def f() do\n  x = 1\n  x + 1\nend\n"
    assert fold_trivial_defs(code) == code
  end

  test "does not fold beyond the line length limit" do
    long_body = "{:ok, \"#{String.duplicate("a", 100)}\"}"
    code = "def f() do\n  #{long_body}\nend\n"
    assert fold_trivial_defs(code) == code
  end

  test "does not fold non-def blocks" do
    code = "if x do\n  :ok\nend\n"
    assert fold_trivial_defs(code) == code
  end
end
