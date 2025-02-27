defmodule Protox.Google.Protobuf.UInt64Value do
  @moduledoc false

  use Protox.Define,
    enums_schemas: %{},
    messages_schemas: %{
      Google.Protobuf.UInt64Value => %Protox.MessageSchema{
        name: Google.Protobuf.UInt64Value,
        syntax: :proto3,
        fields: %{
          value:
            Protox.Field.new!(
              kind: %Protox.Scalar{default_value: 0},
              label: :optional,
              name: :value,
              tag: 1,
              type: :uint64
            )
        }
      }
    }
end
