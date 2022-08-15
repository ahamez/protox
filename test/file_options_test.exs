defmodule FileOptionsTest do
  use ExUnit.Case

  defmodule MyModule do
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
  end

  test "Can read custom option from FileOptions" do
    file_options_1 = MessageWithCustomFileOptions1.file_options()
    assert Map.has_key?(file_options_1, :custom_field)
    assert Map.get(file_options_1, :custom_field) == "bar"

    file_options_2 = MessageWithCustomFileOptions2.file_options()
    assert Map.has_key?(file_options_2, :custom_field)
    assert Map.get(file_options_2, :custom_field) == "bar"
  end
end
