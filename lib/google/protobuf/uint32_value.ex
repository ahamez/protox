defmodule Protox.Google.Protobuf.UInt32Value do
  @moduledoc false

  use Protox.Define,
    enums: %{},
    messages: %{
      Google.Protobuf.UInt32Value => %Protox.Message{
        name: Google.Protobuf.UInt32Value,
        syntax: :proto3,
        fields: [
          Protox.Field.new!(
            kind: {:scalar, 0},
            label: :optional,
            name: :value,
            tag: 1,
            type: :uint32
          )
        ]
      }
    }
end
