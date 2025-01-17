defmodule Protox.Definition do
  @moduledoc false

  # For the time being, we use the type any() as the Parser actually
  # use different types for its internal processing.
  @type t() :: %__MODULE__{
          enums: any(),
          messages: any()
        }

  defstruct enums: %{}, messages: %{}
end
