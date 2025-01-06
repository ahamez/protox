defmodule FileOptionsTest do
  use ExUnit.Case

  use Protox,
    schema: """
    syntax = "proto2";

    import "google/protobuf/descriptor.proto";
    extend google.protobuf.FileOptions {
      optional string custom_field = 50001;
    }

    option (custom_field) = "bar";

    message MessageWithCustomFileOptions1 {
    }

    message MessageWithCustomFileOptions2 {
    }
    """

  use Protox,
    files: [
      "./test/samples/java_bar.proto",
      "./test/samples/java_foo.proto"
    ]

  test "Can read custom option from FileOptions" do
    file_options_1 = MessageWithCustomFileOptions1.file_options()
    assert Map.has_key?(file_options_1, :custom_field)
    assert Map.get(file_options_1, :custom_field) == "bar"

    file_options_2 = MessageWithCustomFileOptions2.file_options()
    assert Map.has_key?(file_options_2, :custom_field)
    assert Map.get(file_options_2, :custom_field) == "bar"
  end

  test "Multiple files don't share the same FileOptions" do
    foo_file_options = JavaFoo.file_options()
    assert Map.get(foo_file_options, :java_package) == "com.foo"

    bar_file_options = JavaBar.file_options()
    assert Map.get(bar_file_options, :java_package) == "com.bar"
  end
end
