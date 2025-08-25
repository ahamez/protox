# Protox

[![Elixir CI](https://github.com/ahamez/protox/actions/workflows/elixir.yml/badge.svg)](https://github.com/ahamez/protox/actions/workflows/elixir.yml)
[![Coverage Status](https://coveralls.io/repos/github/ahamez/protox/badge.svg?branch=master)](https://coveralls.io/github/ahamez/protox?branch=master)
[![Hex.pm Version](https://img.shields.io/hexpm/v/protox.svg)](https://hex.pm/packages/protox)
[![Hex Docs](https://img.shields.io/badge/hex-docs-brightgreen.svg)](https://hexdocs.pm/protox/)
[![Hex.pm Downloads](https://img.shields.io/hexpm/dw/protox)](https://hex.pm/packages/protox)
[![License](https://img.shields.io/hexpm/l/protox.svg)](https://github.com/ahamez/protox/blob/master/LICENSE)

Protox is an Elixir library for working with [Google's Protocol Buffers](https://developers.google.com/protocol-buffers) (proto2 and proto3): encode/decode to/from binary, generate code, or compile schemas at build time.

Protox emphasizes **reliability**: it uses [property testing](https://hexdocs.pm/stream_data), [mutation testing](https://github.com/devonestes/muzak), maintains [near 100% coverage](https://coveralls.io/github/ahamez/protox?branch=master), and [passes Google’s conformance suite](#conformance).

> [!NOTE]
> Using v1? See the v2 migration guide in [v1_to_v2_migration.md](documentation/v1_to_v2_migration.md).

## Example

Given the following protobuf definition:

```proto
message Msg{
  int32 a = 1;
  map<int32, string> b = 2;
}
```

Protox will create a regular Elixir `Msg` struct:

```elixir
iex> msg = %Msg{a: 42, b: %{1 => "a map entry"}}
iex> {:ok, iodata, iodata_size} = Msg.encode(msg)

iex> binary = # read binary from a socket, a file, etc.
iex> {:ok, msg} = Msg.decode(binary)
```

## Usage

You can use Protox in two ways:

1. pass the protobuf schema ([as an inlined schema](#usage-with-an-inlined-schema) or as a [list of files](#usage-with-files)) to the `Protox` macro;
2. [generate](#files-generation) Elixir source code files with the mix task `protox.generate`.

## Prerequisites

- Elixir >= 1.15 and OTP >= 26
- [protoc](https://github.com/protocolbuffers/protobuf/releases) >= 3.0 _This dependency is only required at compile-time_. It must be available in `$PATH`.

## Installation

Add `:protox` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:protox, "~> 2.0"}]
end
```

## Usage with an inlined schema

The following example generates two modules, `Baz` and `Foo`:

```elixir
defmodule MyModule do
  use Protox, schema: """
  syntax = "proto3";

  message Baz {
  }

  message Foo {
    int32 a = 1;
    map<int32, Baz> b = 2;
  }
  """
end
```

> [!NOTE]
> The module in which the `Protox` macro is called is ignored and does not appear in the names of the generated modules. To include the enclosing module’s name, use the `namespace` option, see [here](#prepend-namespaces).

## Usage with files

Use the `:files` option to pass a list of files:

```elixir
defmodule MyModule do
  use Protox, files: [
    "./defs/foo.proto",
    "./defs/bar.proto",
    "./defs/baz/fiz.proto"
  ]
end
```

## Encode

Here's how to encode a message to binary protobuf:

```elixir
msg = %Foo{a: 3, b: %{1 => %Baz{}}}
{:ok, iodata, iodata_size} = Protox.encode(msg)
# or using the bang version
{iodata, iodata_size} = Protox.encode!(msg)
```

You can also call `encode/1` and `encode!/1` directly on the generated structures:

```elixir
{:ok, iodata, iodata_size} = Foo.encode(msg)
{iodata, iodata_size} = Foo.encode!(msg)
```

> [!TIP]
> `encode/1` and `encode!/1` return [iodata](https://hexdocs.pm/elixir/IO.html#module-use-cases-for-io-data) for efficiency. Use it directly with file/socket writes, or convert with `IO.iodata_to_binary/1` when you need a binary.

## Decode

Here's how to decode a message from binary protobuf:

```elixir
{:ok, msg} = Protox.decode(<<8, 3, 18, 4, 8, 1, 18, 0>>, Foo)
# or using the bang version
msg = Protox.decode!(<<8, 3, 18, 4, 8, 1, 18, 0>>, Foo)
```

You can also call `decode/1` and `decode!/1` directly on the generated structures:

```elixir
{:ok, msg} = Foo.decode(<<8, 3, 18, 4, 8, 1, 18, 0>>)
msg = Foo.decode!(<<8, 3, 18, 4, 8, 1, 18, 0>>)
```

## Packages

Protox honors the [`package`](https://protobuf.dev/programming-guides/proto3/#packages) directive:

```proto
package abc.def;
message Baz {}
```

The example above is translated to `Abc.Def.Baz` (package `abc.def` is camelized to `Abc.Def`).

## Namespaces

You can prepend a namespace with a prefix using the `:namespace` option:

```elixir
defmodule Bar do
  use Protox, schema: """
    syntax = "proto3";

    package abc;

    message Msg {
        int32 a = 1;
      }
    """,
    namespace: __MODULE__
end
```

In this example, the module `Bar.Abc.Msg` is generated:

```elixir
msg = %Bar.Abc.Msg{a: 42}
```

## Specify include path

One or more include paths (directories in which to search for imports) can be specified using the `:paths` option:

```elixir
defmodule Baz do
  use Protox,
    files: [
      "./defs1/prefix/foo.proto",
      "./defs1/prefix/bar.proto",
      "./defs2/prefix/baz/baz.proto"
    ],
    paths: [
      "./defs1",
      "./defs2"
    ]
end
```

> [!NOTE]
> It corresponds to the `-I` option of protoc.

## Files generation

It's possible to generate Elixir source code files with the mix task `protox.generate`:

```shell
protox.generate --output-path=/path/to/messages.ex protos/foo.proto protos/bar.proto
```

The files will be usable in any project as long as Protox is declared in the dependencies as functions from its runtime are used.

> [!NOTE]
> protoc is not needed to compile the generated files.

### Options

- `--output-path`

  The path to the file to be generated or to the destination folder when generating multiple files.

- `--include-path`

  Specifies the [include path](#specify-include-path). If multiple include paths are needed, add more `--include-path` options.

- `--multiple-files`

  Generates one file per Elixir module. It's useful for definitions with a lot of messages as the compilation will be parallelized.
  When generating multiple files, the `--output-path` option must point to a directory.

- `--namespace`

  [Prepends a namespace](#prepend-namespaces) to all generated modules.

## Unknown fields

[Unknown fields](https://developers.google.com/protocol-buffers/docs/proto3#unknowns) are fields present on the wire that do not correspond to the protobuf definition. This enables forward-compatibility: older readers keep and re-emit fields added by newer writers.

When unknown fields are encountered at decoding time, they are kept in the decoded message. It's possible to access them with the `unknown_fields/1` function defined with the message.

```elixir
iex> msg = Msg.decode!(<<8, 42, 42, 4, 121, 97, 121, 101, 136, 241, 4, 83>>)
%Msg{a: 42, b: "", z: -42, __uf__: [{5, 2, <<121, 97, 121, 101>>}]}

iex> Msg.unknown_fields(msg)
[{5, 2, <<121, 97, 121, 101>>}]
```

Always use `unknown_fields/1` since the field name (e.g. `__uf__`) is generated to avoid collisions with protobuf fields. It returns a list of `{tag, wire_type, bytes}`. See the [protobuf encoding guide](https://developers.google.com/protocol-buffers/docs/encoding) for details.

> [!NOTE]
> Unknown fields are retained when re-encoding the message.

## Unsupported features

- The [Any](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#any) well-known type is partially supported: you can manually unpack the embedded message after decoding and conversely pack it before encoding;
- Groups ([deprecated in protobuf](https://protobuf.dev/programming-guides/proto2/#groups));
- All [options](https://developers.google.com/protocol-buffers/docs/proto3#options) other than `packed` and `default` are ignored as they concern other languages implementation details.

## Implementation choices

- (**Protobuf 2**) **Required fields** encoding raises `Protox.RequiredFieldsError` when a required field is missing.

  ```elixir
  defmodule Bar do
    use Protox, schema: """
      syntax = "proto2";

      message Required {
        required int32 a = 1;
      }
    """
  end

  iex> Protox.encode!(%Required{})
  ** (Protox.RequiredFieldsError) Some required fields are not set: [:a]
  ```

- (**Protobuf 2**) **Nested extensions** Fields names coming from a nested extension are prefixed with the name of the extender:

  ```protobuf
  message Extendee {
    extensions 100 to max;
  }

  message Extension1 {
    extend Extendee {
      optional Extension1 ext1 = 102;
    }
  }

  message Extension2 {
    extend Extendee {
      optional int32 ext2 = 103;
    }
  }

  message Extension3 {
    extend Extendee {
      optional int32 identical_name = 105;
    }
  }

  message Extension4 {
    extend Extendee {
      repeated int32 identical_name = 106;
    }
  }
  ```

  In the above example, the fields of `Extendee` will be:

  ```elixir
    :extension1_ext1
    :extension2_ext2
    :extension3_identical_name
    :extension4_identical_name
  ```

  This is to disambiguate cases where fields in extensions have the same name.

- **Enum aliases** When decoding, the last encountered constant is used. For instance, in the following example, `:BAR` is always used if the value `1` is read on the wire:

  ```protobuf
  enum E {
    option allow_alias = true;
    FOO = 0;
    BAZ = 1;
    BAR = 1;
  }
  ```

- (**Protobuf 2**) **Unset optional fields** are assigned `nil`. You can use the generated `default/1` function to get the default value of a field:

  ```elixir
  defmodule Bar do
    use Protox,
    schema: """
      syntax = "proto2";

      message Foo {
        optional int32 a = 1 [default = 42];
      }
    """
  end

  iex> %Foo{}.a
  nil

  iex> Foo.default(:a)
  {:ok, 42}
  ```

- (**Protobuf 3**) **Unset fields** are assigned to their [default values](https://developers.google.com/protocol-buffers/docs/proto3#default). However, if you use the `optional` keyword (available in protoc >= 3.15), then unset fields are assigned `nil`:

  ```elixir
  defmodule Bar do
    use Protox,
    schema: """
      syntax = "proto3";

      message Foo {
        int32 a = 1;
        optional int32 b = 2;
      }
    """
  end

  iex> %Foo{}.a
  0

  iex> Foo.default(:a)
  {:ok, 0}

  iex> %Foo{}.b
  nil

  iex> Foo.default(:b)
  {:error, :no_default_value}
  ```

- **Messages and enums names** are converted using the [`Macro.camelize/1`](https://hexdocs.pm/elixir/Macro.html#camelize/1) function.
  Thus, in the following example, `non_camel_message` becomes `NonCamelMessage`, but the field `non_camel_field` is left unchanged:

  ```elixir
  defmodule Bar do
    use Protox,
    schema: """
      syntax = "proto3";

      message non_camel_message {
      }

      message CamelMessage {
        int32 non_camel_field = 1;
      }
    """
  end

  iex> msg = %NonCamelMessage{}
  %NonCamelMessage{__uf__: []}

  iex> msg = %CamelMessage{}
  %CamelMessage{__uf__: [], non_camel_field: 0}
  ```

## Generated code reference and types mapping

- The detailed reference of the generated code is available in [documentation/reference.md](documentation/reference.md).
- Please see [documentation/types_mapping.md](documentation/types_mapping.md) to see how protobuf types are mapped to Elixir types.

## Conformance

The Protox library has been thoroughly tested using the conformance checker [provided by Google](https://github.com/protocolbuffers/protobuf/tree/master/conformance).

Run the suite with:

```shell
mix protox.conformance
```

> [!NOTE]
> A report will be generated in the directory `conformance_report`.

## Benchmark

See [benchmark/launch_benchmark.md](benchmark/launch_benchmark.md) for running benchmarks.

## Contributing

Please see [CONTRIBUTING.md](./CONTRIBUTING.md) for more information on how to contribute.
