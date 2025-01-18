defmodule Protox.Definition do
  @moduledoc false

  @type name() :: atom() | [binary()]
  @type enum_constant() :: {non_neg_integer(), :atom}
  @type t() :: %__MODULE__{
          enums: %{name() => [enum_constant()]},
          messages: %{name() => Protox.Message.t()}
        }

  defstruct enums: %{},
            messages: %{}
end
