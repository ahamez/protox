defmodule Protox.Google.Protobuf.FloatValue do
  @moduledoc false

  use Protox.Define,
    enums: %{},
    messages: %{
      Google.Protobuf.FloatValue => %Protox.Message{
        name: Google.Protobuf.FloatValue,
        syntax: :proto3,
        fields: [
          Protox.Field.new!(
            kind: {:scalar, 0.0},
            label: :optional,
            name: :value,
            tag: 1,
            type: :float
          )
        ]
      }
    }
end
