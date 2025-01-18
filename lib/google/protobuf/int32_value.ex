defmodule Protox.Google.Protobuf.Int32Value do
  @moduledoc false

  use Protox.Define,
    enums: %{},
    messages: %{
      Google.Protobuf.Int32Value => %Protox.Message{
        name: Google.Protobuf.Int32Value,
        syntax: :proto3,
        fields: %{
          value:
            Protox.Field.new!(
              kind: {:scalar, 0},
              label: :optional,
              name: :value,
              tag: 1,
              type: :int32
            )
        }
      }
    }
end
