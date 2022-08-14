defmodule Protox.Google.Protobuf.Empty do
  @moduledoc false

  use Protox.Define,
    enums: [],
    messages: [
      %Protox.Message{
        name: Google.Protobuf.Empty,
        syntax: :proto3,
        fields: []
      }
    ]
end
