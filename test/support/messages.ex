defmodule Protox.Messages do
  @moduledoc false

  use Protox,
    files: [
      "./test/samples/case.proto",
      "./test/samples/google/test_messages_proto2.proto",
      "./test/samples/google/test_messages_proto3.proto",
      "./test/samples/java_bar.proto",
      "./test/samples/java_foo.proto",
      "./test/samples/no_uf_name_clash.proto",
      "./test/samples/optional.proto",
      "./test/samples/protobuf2.proto"
    ]

  # To test the :keep_unknown_fields option.
  use Protox,
    schema: """
    syntax = "proto3";
    message NoUf {}
    """,
    keep_unknown_fields: false

  # For Protox.encode/1 and Protox.decode/2 doctests.
  use Protox,
    schema: """
      syntax = "proto3";

      message ProtoxExample {
        int32 a = 1;
        map<int32, string> b = 2;
      }
    """
end
