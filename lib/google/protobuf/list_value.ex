# Proto definition
# https://github.com/protocolbuffers/protobuf/blob/master/src/google/protobuf/struct.proto

defmodule Protox.Google.Protobuf.ListValue do
  @moduledoc false

  use Protox.Define,
    enums_schemas: %{},
    messages_schemas: %{
      Google.Protobuf.ListValue => %Protox.MessageSchema{
        name: Google.Protobuf.ListValue,
        syntax: :proto3,
        fields: %{
          values:
            Protox.Field.new!(
              kind: :unpacked,
              label: :repeated,
              name: :values,
              tag: 1,
              type: {:message, Google.Protobuf.Value}
            )
        }
      }
    }
end
