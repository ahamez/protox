defmodule Protox.Google.Protobuf.BytesValue do
  @moduledoc false

  use Protox.Define,
    enums: %{},
    messages: %{
      Google.Protobuf.BytesValue => %Protox.Message{
        name: Google.Protobuf.BytesValue,
        syntax: :proto3,
        fields: %{
          value:
            Protox.Field.new!(
              kind: {:scalar, ""},
              label: :optional,
              name: :value,
              tag: 1,
              type: :bytes
            )
        }
      }
    }
end
