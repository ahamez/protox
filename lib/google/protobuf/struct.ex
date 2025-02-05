# Proto definition
# https://github.com/protocolbuffers/protobuf/blob/master/src/google/protobuf/struct.proto

defmodule Protox.Google.Protobuf.Struct do
  @moduledoc false

  use Protox.Define,
    enums_schemas: %{},
    messages_schemas: %{
      Google.Protobuf.Struct => %Protox.MessageSchema{
        name: Google.Protobuf.Struct,
        syntax: :proto3,
        fields: %{
          fields:
            Protox.Field.new!(
              kind: :map,
              label: nil,
              name: :fields,
              tag: 1,
              type: {:string, {:message, Google.Protobuf.Value}}
            )
        }
      }
    }
end
