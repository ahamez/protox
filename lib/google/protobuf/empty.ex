defmodule Protox.Google.Protobuf.Empty do
  @moduledoc false

  use Protox.Define,
    enums_schemas: %{},
    messages_schemas: %{
      Google.Protobuf.Empty => %Protox.MessageSchema{
        name: Google.Protobuf.Empty,
        syntax: :proto3,
        fields: %{}
      }
    }
end
