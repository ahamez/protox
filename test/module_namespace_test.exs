defmodule ModuleNamespaceTest do
  use ExUnit.Case

  defmodule Module do
    use Protox,
      files: [Path.expand("samples/directory/directory_message_1.proto", __DIR__)],
      namespace: __MODULE__
  end

  test "use Protox namespaces generated modules under the caller module" do
    assert Code.ensure_loaded?(ModuleNamespaceTest.Module.DirectoryMessage1)
    assert ModuleNamespaceTest.Module.DirectoryMessage1.schema().name == ModuleNamespaceTest.Module.DirectoryMessage1
  end
end
