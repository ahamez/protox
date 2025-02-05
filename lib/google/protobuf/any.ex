defmodule Protox.Google.Protobuf.Any do
  @moduledoc false

  use Protox.Define,
    enums_schemas: %{},
    messages_schemas: %{
      Google.Protobuf.Any => %Protox.MessageSchema{
        name: Google.Protobuf.Any,
        syntax: :proto3,
        fields: %{
          type_url:
            Protox.Field.new!(
              kind: %Protox.Scalar{default_value: ""},
              label: :optional,
              name: :type_url,
              tag: 1,
              type: :string
            ),
          value:
            Protox.Field.new!(
              kind: %Protox.Scalar{default_value: ""},
              label: :optional,
              name: :value,
              tag: 2,
              type: :bytes
            )
        }
      }
    }
end
