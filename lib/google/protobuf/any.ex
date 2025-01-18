defmodule Protox.Google.Protobuf.Any do
  @moduledoc false

  use Protox.Define,
    enums: %{},
    messages: %{
      Google.Protobuf.Any => %Protox.Message{
        name: Google.Protobuf.Any,
        syntax: :proto3,
        fields: %{
          type_url:
            Protox.Field.new!(
              kind: {:scalar, ""},
              label: :optional,
              name: :type_url,
              tag: 1,
              type: :string
            ),
          value:
            Protox.Field.new!(
              kind: {:scalar, ""},
              label: :optional,
              name: :value,
              tag: 2,
              type: :bytes
            )
        }
      }
    }
end
