# This implementation has been developed by making the conformance tests happy. However, I'm not sure
# they cover everything, and the specification is a little light on details.

defmodule Protox.Google.Protobuf.FieldMask do
  @moduledoc false

  use Protox.Define,
    enums_schemas: %{},
    messages_schemas: %{
      Google.Protobuf.FieldMask => %Protox.MessageSchema{
        name: Google.Protobuf.FieldMask,
        syntax: :proto3,
        fields: %{
          paths:
            Protox.Field.new!(
              kind: :unpacked,
              label: :repeated,
              name: :paths,
              tag: 1,
              type: :string
            )
        }
      }
    }
end
