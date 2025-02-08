# Protox

[![Elixir CI](https://github.com/ahamez/protox/actions/workflows/elixir.yml/badge.svg)](https://github.com/ahamez/protox/actions/workflows/elixir.yml) [![Coverage Status](https://coveralls.io/repos/github/ahamez/protox/badge.svg?branch=master)](https://coveralls.io/github/ahamez/protox?branch=master) [![Hex.pm Version](http://img.shields.io/hexpm/v/protox.svg)](https://hex.pm/packages/protox) [![Hex Docs](https://img.shields.io/badge/hex-docs-brightgreen.svg)](https://hexdocs.pm/protox/) [![License](https://img.shields.io/hexpm/l/protox.svg)](https://github.com/ahamez/protox/blob/master/LICENSE)

Protox is an Elixir library for working with [Google's Protocol Buffers](https://developers.google.com/protocol-buffers), versions 2 and 3, supporting
binary encoding and decoding.

## Example

Given the following protobuf definition, Protox will create a `Msg` struct:
```proto
message Msg{
  int32 a = 1;
  map<int32, string> b = 2;
}
```

You can then interact with `Msg` as with any Elixir structure:

```elixir
iex> msg = %Msg{a: 42, b: %{1 => "a map entry"}}
iex> {:ok, iodata, iodata_size} = Msg.encode(msg)

iex> binary = # read binary from a socket, a file, etc.
iex> {:ok, msg} = Msg.decode(binary)
```

## Reliability

The primary objective of Protox is **reliability**: it uses [property testing](https://github.com/alfert/propcheck), [mutation testing](https://github.com/devonestes/muzak) and has a [near 100% code coverage](https://coveralls.io/github/ahamez/protox?branch=master). Protox [passes all the tests](#conformance) of the conformance checker provided by Google.

## Usage

You can use Protox in two ways:

1. pass the protobuf schema ([as an inlined schema](#usage-with-an-inlined-schema) or as a [list of files](#usage-with-files)) to the `Protox` macro;
2. [generate](#files-generation) Elixir source code files with the mix task `protox.generate`.

## Table of contents

- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Usage with an inlined schema](#usage-with-an-inlined-schema)
- [Usage with files](#usage-with-files)
- [Encode](#encode)
- [Decode](#decode)
- [Packages and namespaces](#packages-and-namespaces)
- [Specify include path](#specify-include-path)
- [Files generation](#files-generation)
- [Unknown fields](#unknown-fields)
- [Unsupported features](#unsupported-features)
- [Implementation choices](#implementation-choices)
- [Generated code reference and types mapping](#generated-code-reference-and-types-mapping)
- [Conformance](#conformance)
- [Benchmark](#benchmark)
- [Contributing](#contributing)

## Prerequisites

- Elixir >= 1.15
- [protoc](https://github.com/protocolbuffers/protobuf/releases) >= 3.0 *This dependency is only required at compile-time*. It must be available in `$PATH`.

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
    "./defs/baz/fiz.proto",
  ]
end
```

## Encode

Here's how to create and encode a new message to binary protobuf:

```elixir
msg = %Foo{a: 3, b: %{1 => %Baz{}}}
{:ok, iodata, iodata_size} = Protox.encode(msg)
# or using the bang version
{iodata, iodata_size} = Protox.encode!(msg)
```

It's also possible to call `encode/1` and `encode!/1` directly on the generated structures:

```elixir
{:ok, iodata, iodata_size} = Foo.encode(msg)
{iodata, iodata_size} = Foo.encode!(msg)
```

> [!NOTE]
> `encode/1` and `encode!/1` return an [IO data](https://hexdocs.pm/elixir/IO.html#module-use-cases-for-io-data) for efficiency reasons. Such IO data can be used directly with files or sockets write operations:
> ```elixir
> iex> {iodata, _iodata_size} = Protox.encode!(%Foo{a: 3, b: %{1 => %Baz{}}})
> {["\b", <<3>>, <<18, 4, 8>>, <<1>>, <<18>>, [<<0>>, []]], 8}
> iex> {:ok, file} = File.open("msg.bin", [:write])
> {:ok, #PID<0.1023.0>}
> iex> IO.binwrite(file, iodata)
> :ok
> ```
>
> Use [`:binary.list_to_bin/1`](https://erlang.org/doc/man/binary.html#list_to_bin-1) or [`IO.iodata_to_binary`](https://hexdocs.pm/elixir/IO.html#iodata_to_binary/1) if you need to get a binary from an IO data.


## Decode

Here's how to decode a message from binary protobuf:

```elixir
{:ok, msg} = Protox.decode(<<8, 3, 18, 4, 8, 1, 18, 0>>, Foo)
# or using the bang version
msg = Protox.decode!(<<8, 3, 18, 4, 8, 1, 18, 0>>, Foo)
```

It's also possible to call `decode/1` and `decode!/1` directly on the generated structures:

```elixir
{:ok, msg} = Foo.decode(<<8, 3, 18, 4, 8, 1, 18, 0>>)
msg = Foo.decode!(<<8, 3, 18, 4, 8, 1, 18, 0>>)
```

## Packages and namespaces

### Packages

Protox honors the [`package`](https://protobuf.dev/programming-guides/proto3/#packages) directive:

```proto
package abc.def;
message Baz {}
```

The example above will be translated to `Abc.Def.Baz` (note the [camelization](#implementation-choices) of package `abc.def` to `Abc.Def`).

### Prepend namespaces
In addition, Protox provides the possibility to prepend a namespace with the `:namespace` option:

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

An include path can be specified using the `:paths` option that specify the directories in which to search for imports:

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

* `--output-path`

  The path to the file to be generated or to the destination folder when generating multiple files.

* `--include-path`

  Specifies the [include path](#specify-include-path). If multiple include paths are needed, add more `--include-path` options.

* `--multiple-files`

  Generates one file per Elixir module. It's useful for definitions with a lot of messages as the compilation will be parallelized.
  When generating multiple files, the `--output-path` option must point to a directory.

* `--namespace`

  [Prepends a namespace](#prepend-namespaces) to all generated modules.

## Unknown fields

[Unknown fields](https://developers.google.com/protocol-buffers/docs/proto3#unknowns) are fields that are present on the wire but which do not correspond to an entry in the protobuf definition. Typically, it occurs when the sender has a newer version of the protobuf definition. It enables backwards compatibility as the receiver with an old version of the protobuf definition will still be able to decode old fields.

When unknown fields are encountered at decoding time, they are kept in the decoded message. It's possible to access them with the  `unknown_fields/1` function defined with the message.

```elixir
iex> msg = Msg.decode!(<<8, 42, 42, 4, 121, 97, 121, 101, 136, 241, 4, 83>>)
%Msg{a: 42, b: "", z: -42, __uf__: [{5, 2, <<121, 97, 121, 101>>}]}

iex> Msg.unknown_fields(msg)
[{5, 2, <<121, 97, 121, 101>>}]
```

You must use `unknown_fields/1` as the name of the field (e.g. `__uf__` in the above example) is generated at compile-time to avoid collision with the actual fields of the Protobuf message. This function returns a list of tuples `{tag, wire_type, bytes}`. For more information, please see [protobuf encoding guide](https://developers.google.com/protocol-buffers/docs/encoding).

> [!NOTE]
> Unknown fields are retained when re-encoding the message.

## Unsupported features

* The [Any](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#any) well-known type is partially supported: you can manually unpack the embedded message after decoding and conversely pack it before encoding;
* Groups ([deprecated in protobuf](https://protobuf.dev/programming-guides/proto2/#groups));
* All [options](https://developers.google.com/protocol-buffers/docs/proto3#options) other than `packed` and `default` are ignored as they concern other languages implementation details.

## Implementation choices

*  (__Protobuf 2__) __Required fields__ Protox enforces the presence of required fields; an error is raised when encoding a message with missing required field:
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

* __Enum aliases__ When decoding, the last encountered constant is used. For instance, in the following example, `:BAR` is always used if the value `1` is read on the wire:
    ```protobuf
    enum E {
      option allow_alias = true;
      FOO = 0;
      BAZ = 1;
      BAR = 1;
    }
    ```

* (__Protobuf 2__) __Unset optional fields__ are assigned `nil`. You can use the generated `default/1` function to get the default value of a field:
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

    iex> Foo.default(:a)
    {:ok, 42}

    iex> %Foo{}.a
    nil

    ```

* (__Protobuf 3__) __Unset fields__ are assigned to their [default values](https://developers.google.com/protocol-buffers/docs/proto3#default). However, if you use the `optional` keyword (available in protoc >= 3.15), then unset fields are assigned `nil`:
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

    iex> Foo.default(:a)
    {:ok, 0}

    iex> %Foo{}.a
    0

    iex> Foo.default(:b)
    {:error, :no_default_value}

    iex> %Foo{}.b
    nil
    ```

* __Messages and enums names__ are converted using the [`Macro.camelize/1`](https://hexdocs.pm/elixir/Macro.html#camelize/1) function.
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

- The detailed reference of the generated code is available [here](documentation/reference.md).
- Please see [reference/types_mapping.md](reference/types_mapping.md) to see how protobuf types are mapped to Elixir types.


## Conformance

The Protox library has been thoroughly tested using the conformance checker [provided by Google](https://github.com/protocolbuffers/protobuf/tree/master/conformance).

To launch these conformance tests, use the `protox.conformance` mix task:
  ```
  $ mix protox.conformance
  WARNING: All log messages before absl::InitializeLog() is called are written to STDERR
  I0000 00:00:1738246114.224098 3490144 conformance_test_runner.cc:394] ./protox_conformance
  CONFORMANCE TEST BEGIN ====================================

  CONFORMANCE SUITE PASSED: 1368 successes, 1307 skipped, 0 expected failures, 0 unexpected failures.

  WARNING: All log messages before absl::InitializeLog() is called are written to STDERR
  I0000 00:00:1738246115.065491 3495574 conformance_test_runner.cc:394] ./protox_conformance
  CONFORMANCE TEST BEGIN ====================================

  CONFORMANCE SUITE PASSED: 0 successes, 414 skipped, 0 expected failures, 0 unexpected failures.
  ```

>[!NOTE]
> A report will be generated in the directory `conformance_report`.


## Benchmark

Please see [benchmark/README.md](benchmark/README.md) for more information on how to launch benchmark.

## Contributing

Please see [CONTRIBUTING.md](CONTRIBUTING.md) for more information on how to contribute.
