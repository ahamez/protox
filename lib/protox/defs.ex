defmodule Protox.MessageDefinitions do
  @enforce_keys [:fields, :tags]
  defstruct fields: %{},
            tags: %{}
end
