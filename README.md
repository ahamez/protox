# Protox

![Elixir CI](https://github.com/ahamez/protox/workflows/Elixir%20CI/badge.svg) [![Coverage Status](https://coveralls.io/repos/github/ahamez/protox/badge.svg?branch=master)](https://coveralls.io/github/ahamez/protox?branch=master) [![Hex Docs](https://img.shields.io/badge/hex-docs-brightgreen.svg)](https://hexdocs.pm/protox/) [![Hex.pm Version](http://img.shields.io/hexpm/v/protox.svg)](https://hex.pm/packages/protox) [![License](https://img.shields.io/hexpm/l/protox.svg)](https://github.com/ahamez/protox/blob/master/LICENSE)

`Protox` is an Elixir library to work with [Google's Protocol Buffers](https://developers.google.com/protocol-buffers) (aka *protobuf*), versions 2 and 3.

The primary objective of `protox` is **reliability**: it uses [property based testing](https://github.com/alfert/propcheck) and has a [near 100% code coverage](https://coveralls.io/github/ahamez/protox?branch=master). Also, using [mutation testing](https://en.wikipedia.org/wiki/Mutation_testing) with the invaluable help of [Muzak pro](https://devonestes.com/muzak), the quality of the `protox` test suite has been validated.
Therefore, `protox` passes all the tests of the conformance checker provided by Google. See [Conformance](#conformance) section for more information.

This library is easy to use: you just point to the `*.proto` files or give the schema to the `Protox` macro, no need to generate any file! However, should you need to generate files, a mix task is available (see [Files generation](#files-generation)).

`Protox` provides a full-blown Elixir experience with protobuf messages. For instance, given the following protobuf `msg.proto` file:
```proto
syntax = "proto3";

message Msg{
  int32 a = 1;
  map<int32, string> b = 2;
}
```

You can interact with `Msg` as if it were a native Elixir structure. For example, note how the protobuf map `b` is translated into an Elixir [map](https://hexdocs.pm/elixir/Map.html):

```elixir
iex> msg = %Msg{a: 42, b: %{1 => "a map entry"}}
iex> {:ok, iodata} = Msg.encode(msg) # or Protox.encode(msg)
...
iex> binary = # read binary from a socket, a file, etc.
iex> {:ok, msg} = Msg.decode(binary)
```

You can find [here](https://github.com/ahamez/protox/blob/master/test/example_test.exs) a more involved example with most types.

## Table of contents

- [Protox](#protox)
  - [Table of contents](#table-of-contents)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
  - [Usage with a textual description](#usage-with-a-textual-description)
  - [Usage with files](#usage-with-files)
  - [Encode](#encode)
  - [Decode](#decode)
  - [Packages and  namespaces](#packages-and--namespaces)
    - [Packages](#packages)
    - [Prepend namespaces](#prepend-namespaces)
  - [Specify import path](#specify-import-path)
  - [Unknown fields](#unknown-fields)
  - [Unsupported features](#unsupported-features)
  - [Implementation choices](#implementation-choices)
  - [Generated code reference](#generated-code-reference)
  - [Files generation](#files-generation)
  - [Conformance](#conformance)
  - [Types mapping](#types-mapping)
  - [Benchmarks](#benchmarks)
  - [Credits](#credits)

## Prerequisites

- Elixir >= 1.7
- protoc >= 3.0
  Protox uses Google's `protoc` (>= 3.0) to parse `.proto` files. It must be available in `$PATH`. You can download it [here](https://github.com/google/protobuf) or you can install it with your favorite package manager (`brew install protobuf`, `apt install protobuf-compiler`, etc.).
  *This dependency is only required at compile-time*.


## Installation

Add `:protox` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:protox, "~> 1.5"}]
end
```

## Usage with a textual description

Here's how to generate the modules from a textual description:

```elixir
defmodule Bar do
  use Protox, schema: """
  syntax = "proto3";

  package fiz;

  message Baz {
  }

  message Foo {
    int32 a = 1;
    map<int32, Baz> b = 2;
  }
  """
end
```

This example will generate two modules: `Fiz.Baz` and `Fiz.Foo`.
Note that the module in which the `Protox` macro is called is completely ignored and therefore does not appear in the names of the generated modules.

## Usage with files

Here's how to generate the modules from a set of files:

```elixir
defmodule Foo do
  use Protox, files: [
    "./defs/foo.proto",
    "./defs/bar.proto",
    "./defs/baz/fiz.proto",
  ]
end
```

Again, the module in which the `Protox` macro is called is completely ignored.

## Encode

Here's how to create and encode a new message:

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
```

Note that `encode/1` returns an [IO data](https://hexdocs.pm/elixir/IO.html#module-use-cases-for-io-data), not a binary, for efficiency reasons. Such  IO data can be used
directly with [files](https://hexdocs.pm/elixir/IO.html#binwrite/2) or sockets write operations, and therefore you don't need to transform them:
```elixir
iex> {:ok, iodata} = Protox.encode(%Fiz.Foo{a: 3, b: %{1 => %Fiz.Baz{}}})
[[[], <<18>>, <<4>>, "\b", <<1>>, <<18>>, <<0>>], "\b", <<3>>]

iex> {:ok, file} = File.open("msg.bin", [:write])
{:ok, #PID<0.1023.0>}

iex> IO.binwrite(file, iodata)
:ok
```

However, you can use [`:binary.list_to_bin/1`](https://erlang.org/doc/man/binary.html#list_to_bin-1) or [`IO.iodata_to_binary`](https://hexdocs.pm/elixir/IO.html#iodata_to_binary/1) to get a binary should the need arises:

```elixir
iex> %Fiz.Foo{a: 3, b: %{1 => %Fiz.Baz{}}} |> Protox.encode!() |> :binary.list_to_bin()
<<8, 3, 18, 4, 8, 1, 18, 0>>
```

## Decode

Here's how to decode a message from a binary:

```elixir
iex> {:ok, msg} = Fiz.Foo.decode(<<8, 3, 18, 4, 8, 1, 18, 0>>)
```
Or, with throwing style:
```elixir
iex> msg = Fiz.Foo.decode!(<<8, 3, 18, 4, 8, 1, 18, 0>>)
```

## Packages and  namespaces

### Packages

Protobuf provides a `package` [directive](https://developers.google.com/protocol-buffers/docs/proto#packages):

```proto
syntax = "proto3";

package abc.def;

message Baz {
}
```

Modules generated by protox will include this package declaration. Thus, the example above will be translated to `Abc.Def.Baz` (note the [camelization](#implementation-choices) of package `abc.def` to `Abc.Def`).

### Prepend namespaces
In addition, protox provides the possibility to prepend a namespace to all generated modules:

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
iex> msg = %MyApp.Msg{a: 42}
```

It's useful to make the generated code appear as being part of your code structure.

## Specify import path

An import path can be specified using the `path:` or `paths:` options that respectively specify the directory or directories in which to search for imports:

```elixir
defmodule Baz do
  use Protox,
    files: [
      "./defs/prefix/foo.proto",
      "./defs/prefix/bar/bar.proto",
    ],
    path: "./defs"
end
```

If multiple search paths are needed:

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

[Unknown fields](https://developers.google.com/protocol-buffers/docs/proto3#unknowns) are fields that are present on the wire but which do not correspond to an entry in the protobuf definition. Typically, it occurs when the sender has a newer version of the protobuf definition. It makes possible to have backward compatibility as the receiver with an old version of the protobuf definition will still be able to decode old fields.

When unknown fields are encountered at decoding time, they are kept in the decoded message. It's possible to access them with the function `unknown_fields/1` defined with the message.

```elixir
iex> msg = Msg.decode!(<<8, 42, 42, 4, 121, 97, 121, 101, 136, 241, 4, 83>>)
%Msg{a: 42, b: "", z: -42, __uf__: [{5, 2, <<121, 97, 121, 101>>}]}

iex> Msg.unknown_fields(msg)
[{5, 2, <<121, 97, 121, 101>>}]
```

You must always use `unknown_fields/1` as the name of the field (e.g. `__uf__` in the above example) is generated at compile-time to avoid collision with the actual fields of the Protobuf message. This function returns a list of tuples `{tag, wire_type, bytes}`. For more information, please see [protobuf encoding guide](https://developers.google.com/protocol-buffers/docs/encoding).

When you encode a message that contains unknown fields, they will be reencoded in the serialized output.

Finally, you can deactivate the support of unknown fields by setting the `:keep_unknown_fields` option to `false`:
```elixir
defmodule Baz do
  use Protox,
    schema: """
    syntax = "proto3";

    message Sub {
      int32 a = 1;
      string b = 2;
    }
    """,
    keep_unknown_fields: false
end
```
Note that protox will still correctly parse unknown fields, they just won't be added to the structure and you won't be able to access them.

## Unsupported features

* Protobuf 3 [JSON mapping](https://developers.google.com/protocol-buffers/docs/proto3#json)
* Groups ([deprecated in protobuf](https://developers.google.com/protocol-buffers/docs/proto#groups))
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

* Messages and enums names: names are converted using the [`Macro.camelize/1`](https://hexdocs.pm/elixir/Macro.html#camelize/1) function.
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

It's also possible to generate a file that will contain all code corresponding to the protobuf messages:

```shell
MIX_ENV=prod mix protox.generate --output-path=/path/to/message.ex --include-path=. test/messages.proto test/samples/proto2.proto
```

The `--include-path` option is the same as the option described in section [Specify import path](#specify-import-path). If multiple include paths are needed, simply add more `--include-path` options.

The generated file will be usable in any project as long as protox is declared in the dependencies (the generated file still needs functions from the protox runtime).

If you have large protobuf files, you can use the `--multiple-files` option to generate one file per module.

```shell
mkdir generated
MIX_ENV=prod mix protox.generate --multiple-files --output-path=generated --include-path=. test/messages.proto test/samples/proto2.proto
```

Doing so, Elixir will be able to parallelize the compilation of generated modules.

It is also possible to prepend a namespace to all generated modules using the `--namespace` option. More information is available in section [Prepend namespaces](#prepend-namespaces).

Finally, you can pass the option `--keep-unknown-fields=false` to remove support of unknown fields. See [this section](#unknown-fields) for more information.

## Conformance

The protox library has been thoroughly tested using the [conformance checker provided by Google](https://github.com/protocolbuffers/protobuf/tree/master/conformance). Note that only the binary part is tested as protox supports only this format. For instance, JSON tests are skipped.

Here's how to launch the conformance test:

* Get conformance-test-runner [sources](https://github.com/protocolbuffers/protobuf/archive/v3.17.3.tar.gz).
* Compile conformance-test-runner ([macOS and Linux only](https://github.com/protocolbuffers/protobuf/tree/master/conformance#portability)):
  `tar xf v3.17.3.tar.gz && cd protobuf-3.17.3 && ./autogen.sh && ./configure && make -j && cd conformance && make -j`.
* Run `mix protox.conformance --runner=/path/to/protobuf-3.17.3/conformance/conformance-test-runner`.
  A report will be generated in a directory `conformance_report`.
  If everything's fine, the following text should be displayed:

  ```
  CONFORMANCE TEST BEGIN ====================================

  CONFORMANCE SUITE PASSED: 1302 successes, 715 skipped, 0 expected failures, 0 unexpected failures.


  CONFORMANCE TEST BEGIN ====================================

  CONFORMANCE SUITE PASSED: 0 successes, 120 skipped, 0 expected failures, 0 unexpected failures.
  ```

You can alternatively launch these conformance tests with `mix test` by setting the `PROTOBUF_CONFORMANCE_RUNNER` environment variable and including the `conformance` tag:
   ```
   PROTOBUF_CONFORMANCE_RUNNER=./protobuf-3.17.3/conformance/conformance-test-runner MIX_ENV=test mix test --include conformance
   ```

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

You can launch benchmarks to see how Protox perform:
```
mix run ./benchmarks/generate_payloads.exs # first time only, generates random payloads
mix run ./benchmarks/run.exs --lib=./benchmarks/protox.exs
mix run ./benchmarks/load.exs
```

## Credits

Both [gpb](https://github.com/tomas-abrahamsson/gpb) and [exprotobuf](https://github.com/bitwalker/exprotobuf) were very useful in understanding how to implement Protocol Buffers.
