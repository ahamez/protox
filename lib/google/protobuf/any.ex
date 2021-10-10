defmodule Protox.Google.Protobuf.Any do
  @moduledoc false

  use Protox.Define,
    enums: [],
    messages: [
      {
        Google.Protobuf.Any,
        :proto3,
        [
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
