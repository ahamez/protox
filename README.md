# Protox

[![Elixir CI](https://github.com/ahamez/protox/actions/workflows/elixir.yml/badge.svg)](https://github.com/ahamez/protox/actions/workflows/elixir.yml) [![Coverage Status](https://coveralls.io/repos/github/ahamez/protox/badge.svg?branch=master)](https://coveralls.io/github/ahamez/protox?branch=master) [![Hex.pm Version](http://img.shields.io/hexpm/v/protox.svg)](https://hex.pm/packages/protox) [![Hex Docs](https://img.shields.io/badge/hex-docs-brightgreen.svg)](https://hexdocs.pm/protox/) [![License](https://img.shields.io/hexpm/l/protox.svg)](https://github.com/ahamez/protox/blob/master/LICENSE)

`protox` is an Elixir library to work with [Google's Protocol Buffers](https://developers.google.com/protocol-buffers), versions 2 and 3. It only supports binary encoding and decoding.

The primary objective of `protox` is **reliability**: it uses [property based testing](https://github.com/alfert/propcheck) and has a [near 100% code coverage](https://coveralls.io/github/ahamez/protox?branch=master). Also, using [mutation testing](https://en.wikipedia.org/wiki/Mutation_testing) with the invaluable help of [Muzak pro](https://devonestes.com/muzak), the quality of the `protox` test suite has been validated. Therefore, `protox` [passes all the tests](#conformance) of the conformance checker provided by Google.

You can use `protox` in two ways:
- either give the protobuf schema (as a list of files or directly as inlined schema) to the `Protox` macro, resulting in the generation of a Elixir module for each message (no files are generated);
- or use the `protox.generate` [mix task](#files-generation) to generate files that will contain all code corresponding to the protobuf messages.

Given the following protobuf definition, `protox` will create a `Msg` struct:
```proto
message Msg{
  int32 a = 1;
  map<int32, string> b = 2;
}
```

You can then interact with `Msg` like any Elixir structure:

```elixir
iex> msg = %Msg{a: 42, b: %{1 => "a map entry"}}
iex> {:ok, iodata} = Msg.encode(msg)

iex> binary = # read binary from a socket, a file, etc.
iex> {:ok, msg} = Msg.decode(binary)
```

## Table of contents

- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Usage with a textual description](#usage-with-a-textual-description)
- [Usage with files](#usage-with-files)
- [Protobuf binary format](#protobuf-binary-format)
- [Packages and  namespaces](#packages-and--namespaces)
- [Specify import path](#specify-import-path)
- [Unknown fields](#unknown-fields)
- [Unsupported features](#unsupported-features)
- [Implementation choices](#implementation-choices)
- [Generated code reference](#generated-code-reference)
- [Files generation](#files-generation)
- [Conformance](#conformance)
- [Types mapping](#types-mapping)
- [Benchmarks](#benchmarks)
- [Contributing](#contributing)
- [Credits](#credits)

## Prerequisites

- Elixir >= 1.15
- protoc >= 3.0 *This dependency is only required at compile-time*
  `protox` uses Google's `protoc` (>= 3.0) to parse `.proto` files. It must be available in `$PATH`.

  👉 You can download it [here](https://github.com/google/protobuf) or you can install it with your favorite package manager (`brew install protobuf`, `apt install protobuf-compiler`, etc.).

  ℹ️ If you choose to generate files, `protoc` won't be needed to compile these files.


## Installation

Add `:protox` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:protox, "~> 1.7"}]
end
```

## Usage with an inlined textual description

The following example generates two modules: `Baz` and `Foo` from a textual description:

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

ℹ️ The module in which the `Protox` macro is called is completely ignored and therefore does not appear in the names of the generated modules.

## Usage with files

Here's how to generate the modules from a set of files:

```elixir
defmodule MyModule do
  use Protox, files: [
    "./defs/foo.proto",
    "./defs/bar.proto",
    "./defs/baz/fiz.proto",
  ]
end
```

## Protobuf binary format

### Encode

Here's how to create and encode a new message to binary protobuf:

```elixir
iex> msg = %Fiz.Foo{a: 3, b: %{1 => %Fiz.Baz{}}}
iex> {:ok, iodata} = Protox.encode(msg)
```
Or, with throwing style:
```elixir
iex> iodata = Protox.encode!(msg)
```

It's also possible to call `encode/1` and `encode!/1` directly on the generated structures:

```elixir
iex> {:ok, iodata} = Fiz.Foo.encode(msg)
iex> iodata = Fiz.Foo.encode!(msg)
```

ℹ️ Note that `encode/1` returns an [IO data](https://hexdocs.pm/elixir/IO.html#module-use-cases-for-io-data) for efficiency reasons. Such  IO data can be used
directly with files or sockets write operations:
```elixir
iex> {:ok, iodata} = Protox.encode(%Fiz.Foo{a: 3, b: %{1 => %Fiz.Baz{}}})
[[[], <<18>>, <<4>>, "\b", <<1>>, <<18>>, <<0>>], "\b", <<3>>]
iex> {:ok, file} = File.open("msg.bin", [:write])
{:ok, #PID<0.1023.0>}
iex> IO.binwrite(file, iodata)
:ok
```

👉 You can use [`:binary.list_to_bin/1`](https://erlang.org/doc/man/binary.html#list_to_bin-1) or [`IO.iodata_to_binary`](https://hexdocs.pm/elixir/IO.html#iodata_to_binary/1) to get a binary:

```elixir
iex> %Fiz.Foo{a: 3, b: %{1 => %Fiz.Baz{}}} |> Protox.encode!() |> :binary.list_to_bin()
<<8, 3, 18, 4, 8, 1, 18, 0>>
```

### Decode

Here's how to decode a message from binary protobuf:

```elixir
iex> {:ok, msg} = Protox.decode(<<8, 3, 18, 4, 8, 1, 18, 0>>, Fiz.Foo)
```
Or, with throwing style:
```elixir
iex> msg = Protox.decode!(<<8, 3, 18, 4, 8, 1, 18, 0>>, Fiz.Foo)
```

It's also possible to call `decode/1` and `decode!/1` directly on the generated structures:

```elixir
iex> {:ok, msg} = Fiz.Foo.decode(<<8, 3, 18, 4, 8, 1, 18, 0>>)
iex> msg = Fiz.Foo.decode!(<<8, 3, 18, 4, 8, 1, 18, 0>>)
```

## Packages and  namespaces

### Packages

Protobuf provides a `package` [directive](https://developers.google.com/protocol-buffers/docs/proto#packages):

```proto
package abc.def;
message Baz {}
```

Modules generated by protox will include this package declaration. Thus, the example above will be translated to `Abc.Def.Baz` (note the [camelization](#implementation-choices) of package `abc.def` to `Abc.Def`).

### Prepend namespaces
In addition, protox provides the possibility to prepend a namespace with the `namespace` option to all generated modules:

```elixir
defmodule Bar do
  use Protox, schema: """
    syntax = "proto3";

    package abc;

    message Msg {
        int32 a = 1;
      }
    """,
    namespace: MyApp
end
```

In this example, the module `MyApp.Abc.Msg` is generated:

```elixir
iex> msg = %MyApp.Abc.Msg{a: 42}
```

## Specify import path

An import path can be specified using the `paths:` option that specify the directories in which to search for imports:

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

It corresponds to the `-I` option of `protoc`.

## Unknown fields

[Unknown fields](https://developers.google.com/protocol-buffers/docs/proto3#unknowns) are fields that are present on the wire but which do not correspond to an entry in the protobuf definition. Typically, it occurs when the sender has a newer version of the protobuf definition. It enables backwards compatibility as the receiver with an old version of the protobuf definition will still be able to decode old fields.

When unknown fields are encountered at decoding time, they are kept in the decoded message. It's possible to access them with the  `unknown_fields/1` function defined with the message.

```elixir
iex> msg = Msg.decode!(<<8, 42, 42, 4, 121, 97, 121, 101, 136, 241, 4, 83>>)
%Msg{a: 42, b: "", z: -42, __uf__: [{5, 2, <<121, 97, 121, 101>>}]}

iex> Msg.unknown_fields(msg)
[{5, 2, <<121, 97, 121, 101>>}]
```

You must always use `unknown_fields/1` as the name of the field (e.g. `__uf__` in the above example) is generated at compile-time to avoid collision with the actual fields of the Protobuf message. This function returns a list of tuples `{tag, wire_type, bytes}`. For more information, please see [protobuf encoding guide](https://developers.google.com/protocol-buffers/docs/encoding).

When you encode a message that contains unknown fields, they will be reencoded in the serialized output.

## Unsupported features

* The [Any](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#any) well-known type is partially supported: you can manually unpack the embedded message right after decoding and conversely pack it right before encoding;
* Groups ([deprecated in protobuf](https://protobuf.dev/programming-guides/proto2/#groups));
* All [options](https://developers.google.com/protocol-buffers/docs/proto3#options) other than `packed` and `default` are ignored as they concern other languages implementation details.

## Implementation choices

* This library enforces the presence of required fields (Protobuf 2). Therefore an error is raised when encoding or decoding a message with a missing required field:
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

    iex> Required.decode!(<<>>)
    ** (Protox.RequiredFieldsError) Some required fields are not set: [:a]
    ```

* When decoding enum aliases, the last encountered constant is used. For instance, in the following example, `:BAR` is always used if the value `1` is read on the wire:
    ```protobuf
    enum E {
      option allow_alias = true;
      FOO = 0;
      BAZ = 1;
      BAR = 1;
    }
    ```

* Unset optionals
    * For Protobuf 2, unset optional fields are mapped to `nil`. You can use the generated `default/1` function to get the default value of a field:
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
        It means that if you need to know if a field has been set by the sender, you just have to test if its value is `nil` or not.

    * For Protobuf 3, unset fields are mapped to their [default values](https://developers.google.com/protocol-buffers/docs/proto3#default). However, if you use the `optional` keyword (available in protoc version 3.15 and higher), then unset fields will be mapped to `nil`:
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

* Messages and enums names: they are converted using the [`Macro.camelize/1`](https://hexdocs.pm/elixir/Macro.html#camelize/1) function.
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

## Generated code reference

The detailed reference of the generated code is available [here](documentation/reference.md).

## Files generation

It's possible to generate a file that will contain all code corresponding to the protobuf messages:

```shell
MIX_ENV=prod mix protox.generate --output-path=/path/to/message.ex --include-path=./test/samples test/samples/messages.proto test/samples/proto2.proto
```

The generated file will be usable in any project as long as `protox` is declared in the dependencies as it needs functions from the protox runtime.


### Options

* `--output-path`
  The path to the file to be generated or to the destination folder when generating multiple files.

* `--include-path`
  Specifies the [import path](#specify-import-path). If multiple include paths are needed, add more `--include-path` options.


* `--multiple-files`
  Generates one file per module. In this case, `--output-path` must point to a directory. It's useful for definitions with a lot of messages as Elixir will be able to parallelize the compilation of the generated modules.

* `--namespace`
  Prepends a [namespace](#prepend-namespaces) to all generated modules.

* `--generate=none|all|unknown_fields`
  Toggles support of features to generate. Currently, only `unknown_fields` is supported.

## Conformance

The protox library has been thoroughly tested using the conformance checker [provided by Google](https://github.com/protocolbuffers/protobuf/tree/master/conformance).

Here's how to launch the conformance tests:

```
mix protox.conformance
```

* A report will be generated in the directory `conformance_report` and the following text should be displayed:

    ```
    CONFORMANCE TEST BEGIN ====================================

    CONFORMANCE SUITE PASSED: 1996 successes, 0 skipped, 21 expected failures, 0 unexpected failures.


    CONFORMANCE TEST BEGIN ====================================

    CONFORMANCE SUITE PASSED: 0 successes, 120 skipped, 0 expected failures, 0 unexpected failures.
    ```

* You can alternatively launch these conformance tests with `mix test` by setting the `PROTOBUF_CONFORMANCE_RUNNER` environment variable and including the `conformance` tag:
     ```
     PROTOBUF_CONFORMANCE_RUNNER=/path/to/conformance-test-runner MIX_ENV=test mix test --include conformance
     ```

### Skipped conformance tests

You may have noticed that there are `XXX expected failures`. Indeed, we removed on purpose some conformance tests that `protox` can't currently pass. Here are the reasons why:

- [Any](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#any) is not yet supported by `protox`;

The exact list of skipped tests is [here](https://github.com/ahamez/protox/blob/master/conformance/failure_list.txt).

## Types mapping

The following table shows how Protobuf types are mapped to Elixir's ones.

Protobuf   | Elixir
---------- | -------------
`int32`    | `integer()`
`int64`    | `integer()`
`uint32`   | `integer()`
`uint64`   | `integer()`
`sint32`   | `integer()`
`sint64`   | `integer()`
`fixed32`  | `integer()`
`fixed64`  | `integer()`
`sfixed32` | `integer()`
`sfixed64` | `integer()`
`float`    | `float() \| :infinity \| :'-infinity' \| :nan`
`double`   | `float() \| :infinity \| :'-infinity' \| :nan`
`bool`     | `boolean()`
`string`   | `String.t()`
`bytes`    | `binary()`
`repeated` | `list(value_type)` where `value_type` is the type of the repeated field
`map`      | `map()`
`oneof`    | `{atom(), value_type}` where `atom()` is the type of the set field and where `value_type` is the type of the set field
`enum`     | `atom() \| integer()`
`message`  | `struct()`

## Benchmarks

You can launch benchmarks to see how `protox` perform:
```
mix run ./benchmarks/generate_payloads.exs # first time only, generates random payloads
mix run ./benchmarks/run.exs --lib=./benchmarks/protox.exs
mix run ./benchmarks/load.exs
```

## Contributing

Please see [CONTRIBUTING.md](CONTRIBUTING.md) for more information.

## Credits

Both [gpb](https://github.com/tomas-abrahamsson/gpb) and [exprotobuf](https://github.com/bitwalker/exprotobuf) were very useful in understanding how to implement Protocol Buffers.
