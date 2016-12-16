defmodule Protox.Field do
  @enforce_keys [:name, :kind, :type]
  defstruct name: nil,
            kind: nil,
            type: nil
end


defmodule Protox.MessageDefinitions do
  @enforce_keys [:name, :fields, :tags]
  defstruct name: nil,
            fields: %{},
            tags: %{}
end


defmodule Protox.Message do
  @enforce_keys [:name]
  defstruct name: nil
end


defmodule Protox.Enumeration do
  @enforce_keys [:members, :values]
  defstruct members: %{},
            values: %{}
end
