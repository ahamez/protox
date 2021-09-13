defmodule Protox.Field do
  @moduledoc false
  # Internal. Describe a field of a message.

  @type t() :: %__MODULE__{
          tag: number(),
          label: atom(),
          name: atom(),
          kind: atom() | {:default, any()} | {:oneof, atom()},
          type: atom() | {atom(), atom()} | {atom(), {:enum | :message, atom()}},
        }

  @keys [:tag, :label, :name, :kind, :type]
  @enforce_keys @keys
  defstruct @keys
end
