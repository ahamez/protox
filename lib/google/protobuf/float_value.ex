defmodule Protox.Google.Protobuf.FloatValue do
  @moduledoc false

  use Protox.Define,
    enums_schemas: %{},
    messages_schemas: %{
      Google.Protobuf.FloatValue => %Protox.MessageSchema{
        name: Google.Protobuf.FloatValue,
        syntax: :proto3,
        fields: %{
          value:
            Protox.Field.new!(
              kind: %Protox.Scalar{default_value: 0.0},
              label: :optional,
              name: :value,
              tag: 1,
              type: :float
            )
        }
      }
    }
end
