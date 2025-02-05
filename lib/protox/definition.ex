defmodule Protox.Definition do
  @moduledoc false

  @type name() :: atom() | [binary()]
  @type enum_constant() :: {non_neg_integer(), :atom}
  @type t() :: %__MODULE__{
          enums_schemas: %{name() => [enum_constant()]},
          messages_schemas: %{name() => Protox.MessageSchema.t()}
        }

  defstruct enums_schemas: %{},
            messages_schemas: %{}
end
