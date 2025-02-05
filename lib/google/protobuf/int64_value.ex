defmodule Protox.Google.Protobuf.Int64Value do
  @moduledoc false

  use Protox.Define,
    enums_schemas: %{},
    messages_schemas: %{
      Google.Protobuf.Int64Value => %Protox.MessageSchema{
        name: Google.Protobuf.Int64Value,
        syntax: :proto3,
        fields: %{
          value:
            Protox.Field.new!(
              kind: %Protox.Scalar{default_value: 0},
              label: :optional,
              name: :value,
              tag: 1,
              type: :int64
            )
        }
      }
    }
end
