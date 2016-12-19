defmodule Protox.Field do
  @enforce_keys [:name, :kind, :type]
  defstruct name: nil,
            kind: nil,
            type: nil
end


defmodule Protox.MessageDefinitions do
  @enforce_keys [:fields, :tags]
  defstruct fields: %{},
            tags: %{}
end
