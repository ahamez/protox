defmodule Protox.Field do
  @moduledoc false

  @type t() :: %__MODULE__{
          tag: number(),
          label: atom(),
          name: atom(),
          kind: atom() | {:default, any()},
          type: atom() | {atom(), atom()} | {atom(), {:enum | :message, atom()}}
        }

  @keys [:tag, :label, :name, :kind, :type]
  @enforce_keys @keys
  defstruct @keys
end
