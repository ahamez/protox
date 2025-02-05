defmodule Protox.Google.Protobuf.BytesValue do
  @moduledoc false

  use Protox.Define,
    enums_schemas: %{},
    messages_schemas: %{
      Google.Protobuf.BytesValue => %Protox.MessageSchema{
        name: Google.Protobuf.BytesValue,
        syntax: :proto3,
        fields: %{
          value:
            Protox.Field.new!(
              kind: %Protox.Scalar{default_value: ""},
              label: :optional,
              name: :value,
              tag: 1,
              type: :bytes
            )
        }
      }
    }
end
