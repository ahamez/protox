defmodule Protox.Messages do
  @moduledoc false

  use Protox,
    files: [
      "./test/samples/messages.proto"
    ]

  use Protox,
    files: [
      "./test/samples/messages.proto",
      "./test/samples/test_messages_proto3.proto"
    ],
    namespace: WithJason,
    json_library: Jason

  use Protox,
    files: [
      "./test/samples/messages.proto"
    ],
    namespace: WithDummyJsonLibrary,
    json_library: DummyJsonLibrary

  use Protox,
    files: [
      "./test/samples/messages.proto",
      "./test/samples/test_messages_proto3.proto"
    ],
    namespace: WithPoison,
    json_library: Poison
end
