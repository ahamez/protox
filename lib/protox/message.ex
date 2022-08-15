defmodule Protox.Message do
  @moduledoc false

  @type t() :: %__MODULE__{
          name: atom(),
          syntax: atom(),
          fields: list(Protox.Field.t()),
          file_options: struct() | nil
        }

  @enforced_keys [:name, :syntax, :fields]
  @enforce_keys @enforced_keys
  defstruct @enforced_keys ++ [:file_options]
end
