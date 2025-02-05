# Proto definition
# https://github.com/protocolbuffers/protobuf/blob/master/src/google/protobuf/struct.proto

defmodule Protox.Google.Protobuf.Value do
  @moduledoc false

  use Protox.Define,
    enums_schemas: %{},
    messages_schemas: %{
      Google.Protobuf.Value => %Protox.MessageSchema{
        name: Google.Protobuf.Value,
        syntax: :proto3,
        fields: %{
          null_value:
            Protox.Field.new!(
              kind: %Protox.OneOf{parent: :kind},
              label: :optional,
              name: :null_value,
              tag: 1,
              type: {:enum, Google.Protobuf.NullValue}
            ),
          number_value:
            Protox.Field.new!(
              kind: %Protox.OneOf{parent: :kind},
              label: :optional,
              name: :number_value,
              tag: 2,
              type: :double
            ),
          string_value:
            Protox.Field.new!(
              kind: %Protox.OneOf{parent: :kind},
              label: :optional,
              name: :string_value,
              tag: 3,
              type: :string
            ),
          bool_value:
            Protox.Field.new!(
              kind: %Protox.OneOf{parent: :kind},
              label: :optional,
              name: :bool_value,
              tag: 4,
              type: :bool
            ),
          struct_value:
            Protox.Field.new!(
              kind: %Protox.OneOf{parent: :kind},
              label: :optional,
              name: :struct_value,
              tag: 5,
              type: {:message, Google.Protobuf.Struct}
            ),
          list_value:
            Protox.Field.new!(
              kind: %Protox.OneOf{parent: :kind},
              label: :optional,
              name: :list_value,
              tag: 6,
              type: {:message, Google.Protobuf.ListValue}
            )
        }
      }
    }
end
