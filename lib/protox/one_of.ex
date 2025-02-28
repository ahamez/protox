defmodule Protox.OneOf do
  @moduledoc """
  Represents a [oneof field](https://protobuf.dev/programming-guides/proto3/#oneof) in protobuf.

  A oneof field represents a group of fields where only one of them can be set at a time.
  This module provides a struct to store the parent field of this oneof group, that is, the
  field that effectively contains the set value.

  ## Fields

  * `:parent` - The name the parent field of this oneof group.
  """

  @type t() :: %__MODULE__{
          parent: atom()
        }

  @enforce_keys [:parent]
  defstruct [:parent]
end
