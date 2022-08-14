defmodule Protox.Google.Protobuf.Any do
  @moduledoc false

  use Protox.Define,
    enums: [],
    messages: [
      %Protox.Message{
        name: Google.Protobuf.Any,
        syntax: :proto3,
        fields: [
          Protox.Field.new!(
            kind: {:scalar, ""},
            label: :optional,
            name: :type_url,
            tag: 1,
            type: :string
          ),
          Protox.Field.new!(
            kind: {:scalar, ""},
            label: :optional,
            name: :value,
            tag: 2,
            type: :bytes
          )
        ]
      }
    ]
end
