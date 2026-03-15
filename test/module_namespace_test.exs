defmodule ModuleNamespaceTest do
  use ExUnit.Case

  import ExUnit.CaptureIO

  defmodule Module do
    use Protox,
      files: [Path.expand("samples/directory/directory_message_1.proto", __DIR__)],
      prefix: __MODULE__
  end

  test "use Protox namespaces generated modules under the caller module with prefix" do
    assert Code.ensure_loaded?(ModuleNamespaceTest.Module.DirectoryMessage1)
    assert ModuleNamespaceTest.Module.DirectoryMessage1.schema().name == ModuleNamespaceTest.Module.DirectoryMessage1
  end

  test "use Protox keeps namespace working and warns when given a computed expression" do
    warning =
      capture_io(:stderr, fn ->
        Code.compile_string("""
        defmodule ModuleNamespaceTest.ComputedNamespace do
          use Protox,
            files: [Path.expand("samples/directory/directory_message_1.proto", #{inspect(__DIR__)})],
            namespace: Module.concat(__MODULE__, Generated)
        end
        """)
      end)

    generated_module = ModuleNamespaceTest.ComputedNamespace.Generated.DirectoryMessage1

    assert warning =~ "`use Protox, namespace: ...` is deprecated; use `prefix: ...` instead"
    assert Code.ensure_loaded?(generated_module)

    assert apply(generated_module, :schema, []).name == generated_module
  end

  test "use Protox keeps namespace working and warns when given __MODULE__" do
    warning =
      capture_io(:stderr, fn ->
        Code.compile_string("""
        defmodule ModuleNamespaceTest.DeprecatedNamespace do
          use Protox,
            files: [Path.expand("samples/directory/directory_message_1.proto", #{inspect(__DIR__)})],
            namespace: __MODULE__
        end
        """)
      end)

    assert warning =~ "`use Protox, namespace: ...` is deprecated; use `prefix: ...` instead"
    assert Code.ensure_loaded?(ModuleNamespaceTest.DeprecatedNamespace.DirectoryMessage1)
  end

  test "use Protox rejects computed prefix expressions" do
    assert_raise ArgumentError,
                 ~r/invalid Protox option :prefix/,
                 fn ->
                   Code.compile_string("""
                   defmodule ModuleNamespaceTest.InvalidPrefix do
                     def namespace, do: __MODULE__.Generated

                     use Protox,
                       files: [Path.expand("samples/directory/directory_message_1.proto", #{inspect(__DIR__)})],
                       prefix: namespace()
                   end
                   """)
                 end
  end

  test "use Protox rejects namespace and prefix together" do
    assert_raise ArgumentError,
                 ~r/options :namespace and :prefix are mutually exclusive/,
                 fn ->
                   Code.compile_string("""
                   defmodule ModuleNamespaceTest.ConflictingNamespaceOptions do
                     use Protox,
                       files: [Path.expand("samples/directory/directory_message_1.proto", #{inspect(__DIR__)})],
                       namespace: __MODULE__,
                       prefix: __MODULE__
                   end
                   """)
                 end
  end
end
