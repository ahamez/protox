defmodule Protox.Google.Protobuf.BoolValue do
  @moduledoc false

  use Protox.Define,
    enums_schemas: %{},
    messages_schemas: %{
      Google.Protobuf.BoolValue => %Protox.MessageSchema{
        name: Google.Protobuf.BoolValue,
        syntax: :proto3,
        fields: %{
          value:
            Protox.Field.new!(
              kind: %Protox.Scalar{default_value: false},
              label: :optional,
              name: :value,
              tag: 1,
              type: :bool
            )
        }
      }
    }
end
