# Proto definition
# https://github.com/protocolbuffers/protobuf/blob/master/src/google/protobuf/struct.proto

defmodule Protox.Google.Protobuf.Value do
  @moduledoc false

  use Protox.Define,
    enums: [],
    messages: [
      %Protox.Message{
        name: Google.Protobuf.Value,
        syntax: :proto3,
        fields: [
          Protox.Field.new!(
            kind: {:oneof, :kind},
            label: :optional,
            name: :null_value,
            tag: 1,
            type: {:enum, Google.Protobuf.NullValue}
          ),
          Protox.Field.new!(
            kind: {:oneof, :kind},
            label: :optional,
            name: :number_value,
            tag: 2,
            type: :double
          ),
          Protox.Field.new!(
            kind: {:oneof, :kind},
            label: :optional,
            name: :string_value,
            tag: 3,
            type: :string
          ),
          Protox.Field.new!(
            kind: {:oneof, :kind},
            label: :optional,
            name: :bool_value,
            tag: 4,
            type: :bool
          ),
          Protox.Field.new!(
            kind: {:oneof, :kind},
            label: :optional,
            name: :struct_value,
            tag: 5,
            type: {:message, Google.Protobuf.Struct}
          ),
          Protox.Field.new!(
            kind: {:oneof, :kind},
            label: :optional,
            name: :list_value,
            tag: 6,
            type: {:message, Google.Protobuf.ListValue}
          )
        ]
      }
    ]
end
