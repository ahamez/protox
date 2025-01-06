defmodule Protox.Google.Protobuf.DoubleValue do
  @moduledoc false

  use Protox.Define,
    enums: [],
    messages: [
      %Protox.Message{
        name: Google.Protobuf.DoubleValue,
        syntax: :proto3,
        fields: [
          Protox.Field.new!(
            kind: {:scalar, 0.0},
            label: :optional,
            name: :value,
            tag: 1,
            type: :double
          )
        ]
      }
    ]
end
