defmodule FileOptionsTest do
  use ExUnit.Case

  test "Can read custom option from FileOptions" do
    file_options_1 = MessageWithCustomFileOptions.file_options()
    assert Map.has_key?(file_options_1, :custom_field)
    assert Map.get(file_options_1, :custom_field) == "bar"
  end

  test "Multiple files don't share the same FileOptions" do
    foo_file_options = JavaFoo.file_options()
    assert Map.get(foo_file_options, :java_package) == "com.foo"

    bar_file_options = JavaBar.file_options()
    assert Map.get(bar_file_options, :java_package) == "com.bar"
  end
end
