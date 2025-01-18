defmodule Protox.Google.Protobuf.Int64Value do
  @moduledoc false

  use Protox.Define,
    enums: %{},
    messages: %{
      Google.Protobuf.Int64Value => %Protox.Message{
        name: Google.Protobuf.Int64Value,
        syntax: :proto3,
        fields: [
          Protox.Field.new!(
            kind: {:scalar, 0},
            label: :optional,
            name: :value,
            tag: 1,
            type: :int64
          )
        ]
      }
    }
end
