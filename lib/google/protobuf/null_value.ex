# Proto definition
# https://github.com/protocolbuffers/protobuf/blob/master/src/google/protobuf/struct.proto

defmodule Protox.Google.Protobuf.NullValue do
  @moduledoc false

  use Protox.Define,
    enums: %{
      Google.Protobuf.NullValue => [
        {0, :NULL_VALUE}
      ]
    },
    messages: %{}
end
