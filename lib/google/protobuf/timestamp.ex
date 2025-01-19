defmodule Protox.Google.Protobuf.Timestamp do
  @moduledoc false

  use Protox.Define,
    enums: %{},
    messages: %{
      Google.Protobuf.Timestamp => %Protox.Message{
        name: Google.Protobuf.Timestamp,
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
