defmodule FileOptionsTest do
  use ExUnit.Case

  # For a reason I don't understand, the custom option defined in
  # custom_file_options.proto is not available if we add this file
  # to the list of files to parse in `test/support/messages.ex`.
  #
  # However, if defined directly in the test file, it works fine.
  use Protox,
    files: [
      "./test/samples/custom_file_options.proto",
      "./test/samples/message_as_file_option.proto",
      "./test/samples/use_message_as_file_option.proto"
    ]

  test "Can read custom option from FileOptions" do
    file_options = MessageWithCustomFileOptions.schema().file_options
    assert Map.has_key?(file_options, :custom_field)
    assert Map.get(file_options, :custom_field) == "bar"
  end

  test "Multiple files don't share the same FileOptions" do
    foo_file_options = JavaFoo.schema().file_options
    assert Map.get(foo_file_options, :java_package) == "com.foo"

    bar_file_options = JavaBar.schema().file_options
    assert Map.get(bar_file_options, :java_package) == "com.bar"
  end

  test "Can read custom option (which is a message) from FileOptions" do
    file_options = Protox.Test.DummyMessage.schema().file_options
    assert Map.has_key?(file_options, :msg_as_file_option)
    assert Map.get(file_options, :msg_as_file_option) == %Protox.Test.MsgAsFileOption{a: 42}
  end
end
