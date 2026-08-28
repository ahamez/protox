defmodule Protox.Varint.DecodeClauses do
  @moduledoc false
  # Internal. Compile-time builder for unrolled LEB128-decoding clauses, shared
  # by Protox.Varint.decode/1 and the packed varint loops of Protox.Decode so
  # both unroll the exact same decoding. It lives outside those modules because
  # a module cannot call its own functions from its own body.

  # Imported so the quoted <<< and ||| below carry the Bitwise import with them.
  import Bitwise

  @byte_var_names ~w(b0 b1 b2 b3 b4 b5 b6 b7 b8 b9)a

  # Returns one {pattern, value} pair per varint encoded length in `lengths`.
  # `pattern` matches the varint bytes followed by `rest_var::binary`; `value`
  # is the decoded integer. Callers splice both into their own clauses.
  @spec build(Range.t(), Macro.t()) :: [{Macro.t(), Macro.t()}]
  def build(lengths, rest_var) do
    for len <- lengths do
      byte_vars =
        @byte_var_names
        |> Enum.take(len)
        |> Enum.map(&Macro.var(&1, __MODULE__))

      segments =
        byte_vars
        |> Enum.with_index()
        |> Enum.flat_map(fn {var, index} ->
          [quote(do: unquote(continuation_bit(index, len)) :: 1), quote(do: unquote(var) :: 7)]
        end)

      pattern = quote(do: <<unquote_splicing(segments ++ [quote(do: unquote(rest_var) :: binary)])>>)

      value =
        byte_vars
        |> Enum.with_index()
        |> Enum.map(fn
          {var, 0} -> var
          {var, index} -> quote(do: unquote(var) <<< unquote(7 * index))
        end)
        |> Enum.reduce(&quote(do: unquote(&2) ||| unquote(&1)))

      {pattern, value}
    end
  end

  # The last byte of a varint has its continuation bit cleared; every other byte has it set.
  defp continuation_bit(index, len) when index == len - 1, do: 0
  defp continuation_bit(_index, _len), do: 1
end
