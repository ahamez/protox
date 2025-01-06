defmodule Protox.Messages do
  @moduledoc false

  use Protox,
    files: [
      "./test/samples/messages.proto"
    ]

  # For Protox.encode doctests
  use Protox,
    schema: """
      syntax = "proto3";

      message EncodeExample {
        int32 a = 1;
        map<int32, string> b = 2;
      }
    """

  use Protox,
    schema: """
    syntax = "proto3";

    enum FooBarEnum {
        FOO = 0;
        BAR = 1;
      }
    """

  use Protox,
    files: [
      "./test/samples/proto2.proto",
      "./test/samples/proto2_extension.proto",
      "./test/samples/proto3.proto"
    ]

  use Protox,
    files: [
      "./test/samples/proto2.proto",
      "./test/samples/proto2_extension.proto",
      "./test/samples/proto3.proto"
    ],
    namespace: Namespace

  use Protox,
    files: [
      "./test/samples/prefix/foo.proto",
      "./test/samples/prefix/bar/bar.proto"
    ],
    namespace: TestPrefix,
    path: Path.join(__DIR__, "test/samples")

  use Protox,
    files: [
      "./test/samples/prefix/baz.proto"
    ],
    namespace: TestPrefix,
    path: "./test/samples"

  use Protox,
    schema: """
    syntax = "proto3";

    message non_camel {
      int32 x = 1;
    }

    message Camel {
      non_camel x = 1;
    }
    """

  use Protox,
    schema: """
    syntax = "proto3";

    message Sub {
      int32 a = 1;
      string b = 2;
      sint32 z = 10001;
    }
    """,
    namespace: NoUf,
    keep_unknown_fields: false

  use Protox,
    schema: """
    syntax = "proto3";

    message NoDefsFuns {
    }
    """

  use Protox,
    schema: """
    syntax = "proto3";

    message MsgWithNonCamelEnum {
      snake_case snake_case = 2;
    }

    enum snake_case {
      c = 0;
      d = 1;
    }
    """

  use Protox,
    schema: """
    syntax = "proto3";

    message MsgWithNonCamelEnum {
      snake_case snake_case = 2;
    }

    enum snake_case {
      c = 0;
      d = 1;
    }
    """,
    namespace: AnotherNamespace

  use Protox,
    schema: """
      syntax = "proto3";

      message Msg1 {
        optional int32 foo = 1;
      }

      message Msg2 {
        oneof _foo {
          int32 foo = 1;
        }
      }

      message Msg3 {
        optional Msg1 foo = 1;
      }

      message Msg4 {
        oneof _foo {
          Msg1 foo = 1;
        }
      }
    """
end
