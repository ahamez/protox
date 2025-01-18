defmodule Protox.Google.Protobuf.BoolValue do
  @moduledoc false

  use Protox.Define,
    enums: %{},
    messages: %{
      Google.Protobuf.BoolValue => %Protox.Message{
        name: Google.Protobuf.BoolValue,
        syntax: :proto3,
        fields: %{
          value:
            Protox.Field.new!(
              kind: {:scalar, false},
              label: :optional,
              name: :value,
              tag: 1,
              type: :bool
            )
        }
      }
    }
end
