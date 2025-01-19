defmodule Protox.Google.Protobuf.DoubleValue do
  @moduledoc false

  use Protox.Define,
    enums: %{},
    messages: %{
      Google.Protobuf.DoubleValue => %Protox.Message{
        name: Google.Protobuf.DoubleValue,
        syntax: :proto3,
        fields: %{
          value:
            Protox.Field.new!(
              kind: %Protox.Scalar{default_value: 0.0},
              label: :optional,
              name: :value,
              tag: 1,
              type: :double
            )
        }
      }
    }
end
