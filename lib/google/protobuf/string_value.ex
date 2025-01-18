defmodule Protox.Google.Protobuf.StringValue do
  @moduledoc false

  use Protox.Define,
    enums: %{},
    messages: %{
      Google.Protobuf.StringValue => %Protox.Message{
        name: Google.Protobuf.StringValue,
        syntax: :proto3,
        fields: [
          Protox.Field.new!(
            kind: {:scalar, ""},
            label: :optional,
            name: :value,
            tag: 1,
            type: :string
          )
        ]
      }
    }
end
