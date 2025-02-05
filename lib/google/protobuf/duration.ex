defmodule Protox.Google.Protobuf.Duration do
  @moduledoc false

  use Protox.Define,
    enums_schemas: %{},
    messages_schemas: %{
      Google.Protobuf.Duration => %Protox.MessageSchema{
        name: Google.Protobuf.Duration,
        syntax: :proto3,
        fields: %{
          seconds:
            Protox.Field.new!(
              kind: %Protox.Scalar{default_value: 0},
              label: :optional,
              name: :seconds,
              tag: 1,
              type: :int64
            ),
          nanos:
            Protox.Field.new!(
              kind: %Protox.Scalar{default_value: 0},
              label: :optional,
              name: :nanos,
              tag: 2,
              type: :int32
            )
        }
      }
    }
end
