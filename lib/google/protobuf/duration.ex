defmodule Protox.Google.Protobuf.Duration do
  @moduledoc false

  use Protox.Define,
    enums: %{},
    messages: %{
      Google.Protobuf.Duration => %Protox.Message{
        name: Google.Protobuf.Duration,
        syntax: :proto3,
        fields: %{
          seconds:
            Protox.Field.new!(
              kind: {:scalar, 0},
              label: :optional,
              name: :seconds,
              tag: 1,
              type: :int64
            ),
          nanos:
            Protox.Field.new!(
              kind: {:scalar, 0},
              label: :optional,
              name: :nanos,
              tag: 2,
              type: :int32
            )
        }
      }
    }
end
