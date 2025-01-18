# Proto definition
# https://github.com/protocolbuffers/protobuf/blob/master/src/google/protobuf/struct.proto

defmodule Protox.Google.Protobuf.Struct do
  @moduledoc false

  use Protox.Define,
    enums: %{},
    messages: %{
      Google.Protobuf.Struct => %Protox.Message{
        name: Google.Protobuf.Struct,
        syntax: :proto3,
        fields: [
          Protox.Field.new!(
            kind: :map,
            label: nil,
            name: :fields,
            tag: 1,
            type: {:string, {:message, Google.Protobuf.Value}}
          )
        ]
      }
    }
end
