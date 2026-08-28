defmodule Protox.RandomInit.Values do
  @moduledoc false

  # Decides *what values* a generated message carries. Walking a schema — oneof parents,
  # map key types, well-known types, recursion depth — stays in `Protox.RandomInit`; only
  # the leaf distributions differ between profiles.
  #
  # `Protox.RandomInit.EdgeCase` is the default and is what the test suite uses: it hunts
  # NaN, Infinity, full-range integers and awkward unicode. The benchmark passes a profile
  # with production-like distributions instead, because those edge cases are exactly the
  # code paths real traffic does not take.

  @doc "Generator for a scalar protobuf type, e.g. `:int32`, `:string`, `{:enum, Mod}`."
  @callback scalar(type :: term()) :: StreamData.t()

  @doc """
  Wraps an element generator into a repeated field generator.

  `depth` is the recursion budget left. At zero a nested message can only come out empty,
  so a profile may prefer an empty list over a list of blank messages.
  """
  @callback collection(element :: StreamData.t(), depth :: non_neg_integer()) :: StreamData.t()

  @doc """
  Decides whether an optional sub-message is present.

  `depth` is the recursion budget left; see `c:collection/2`.
  """
  @callback presence(message :: StreamData.t(), depth :: non_neg_integer()) :: StreamData.t()

  @doc "Builds a map field generator from its key type and its key/value generators."
  @callback map(key_type :: term(), key :: StreamData.t(), value :: StreamData.t()) :: StreamData.t()
end
