defmodule ModuleNamespaceTest do
  use ExUnit.Case, async: true

  alias ModuleNamespaceTest.Module.DirectoryMessage1

  defmodule Module do
    use Protox,
      files: [Path.expand("samples/directory/directory_message_1.proto", __DIR__)],
      namespace: __MODULE__
  end

  test "use Protox namespaces generated modules under the caller module" do
    assert Code.ensure_loaded?(DirectoryMessage1)
    assert DirectoryMessage1.schema().name == DirectoryMessage1
  end
end
