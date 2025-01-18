defmodule Protox.Google.Protobuf.UInt64Value do
  @moduledoc false

  use Protox.Define,
    enums: %{},
    messages: %{
      Google.Protobuf.UInt64Value => %Protox.Message{
        name: Google.Protobuf.UInt64Value,
        syntax: :proto3,
        fields: [
          Protox.Field.new!(
            kind: {:scalar, 0},
            label: :optional,
            name: :value,
            tag: 1,
            type: :uint64
          )
        ]
      }
    }
end
