defmodule Protox.Definition do
  @moduledoc false

  @type t :: %__MODULE__{
          enums: map(),
          messages: map()
        }

  defstruct enums: %{}, messages: %{}
end
