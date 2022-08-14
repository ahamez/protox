defmodule Protox.Message do
  @moduledoc false

  @type t() :: %__MODULE__{
          name: binary(),
          syntax: atom(),
          fields: list(Protox.Field.t())
        }

  @keys [:name, :syntax, :fields]
  @enforce_keys @keys
  defstruct @keys
end
