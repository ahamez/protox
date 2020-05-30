# Protox

[![Build Status](https://travis-ci.org/EasyMile/protox.svg?branch=master)](https://travis-ci.org/EasyMile/protox) [![Coverage Status](https://coveralls.io/repos/github/EasyMile/protox/badge.svg?branch=master)](https://coveralls.io/github/EasyMile/protox?branch=master) [![Hex.pm Version](http://img.shields.io/hexpm/v/protox.svg)](https://hex.pm/packages/protox) [![Inline docs](http://inch-ci.org/github/EasyMile/protox.svg)](http://inch-ci.org/github/EasyMile/protox)


Protox is a native Elixir library to work with Google's Protocol Buffers (version 2 and 3).

This library passes all the tests of the conformance checker provided by Google. See the Conformance section for more information.


# Prerequisites

Protox uses Google `protoc` (>= 3.0) to parse `.proto` files. It must be available in `$PATH`. This dependency is only required at compile time.
You can get it [here](https://github.com/google/protobuf).


# Usage

## From a Textual Description

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

The previous example generates two modules: `Fiz.Baz` and `Fiz.Foo`.
Note that the module in which the `Protox` macro is called is completely ignored.

## From Files

```elixir
defmodule Foo do
  @external_resource "./defs/foo.proto"
  @external_resource "./defs/bar.proto"
  @external_resource "./defs/baz/fiz.proto"

  use Protox, files: [
    "./defs/foo.proto",
    "./defs/bar.proto",
    "./defs/baz/fiz.proto",
  ]
end
```

## Working With Namespaces

It is possible to prepend a namespace to all generated modules:

```elixir
defmodule Bar do
  use Protox, schema: """
    syntax = "proto3";

    enum Enum {
        FOO = 0;
        BAR = 1;
      }
    """,
    namespace: Namespace
end
```

In this case, the module `Namespace.Enum` is generated.

## Specify import path

An import path can be specified using the `path:` option:

```elixir
defmodule Baz do
  @external_resource "./defs/prefix/foo.proto"
  @external_resource "./defs/prefix/bar/bar.proto"

  use Protox,
    files: [
      "./defs/prefix/foo.proto",
      "./defs/prefix/bar/bar.proto",
    ],
    path: "./defs"
end
```

It corresponds to the `-I` option of `protoc`.

## Encode

```elixir
iex> %Fiz.Foo{a: 3, b: %{1 => %Fiz.Baz{}}} |> Protox.Encode.encode()
[[[], "\b", <<3>>], <<18>>, <<4>>, "\b", <<1>>, <<18>>, <<0>>]
```

Note that `Protox.Encode.encode/1` returns an IO list, not a binary. Such IO lists can be used
directly with files or sockets write operations.
However, you can use `:binary.list_to_bin/1` to get a binary:

```elixir
iex> %Fiz.Foo{a: 3, b: %{1 => %Fiz.Baz{}}} |> Protox.Encode.encode() |> :binary.list_to_bin()
<<8, 3, 18, 4, 8, 1, 18, 0>>
```

## Decode

```elixir
iex> <<8, 3, 18, 4, 8, 1, 18, 0>> |> Fiz.Foo.decode()
{:ok,
 %Fiz.Foo{__uf__: [], a: 3,
  b: %{1 => %Fiz.Baz{__uf__: []}}}}
```

The `__uf__` field is explained in the section [Unknown fields](https://github.com/EasyMile/protox#unknown-fields).


# Unknown Fields

If any unknown field is encountered when decoding, it is kept in the decoded message.
It is possible to access them with the function `unknown_fields/1` defined with the message.

```elixir
iex> msg = <<8, 42, 42, 4, 121, 97, 121, 101, 136, 241, 4, 83>> |> Msg.decode!()
%Msg{a: 42, b: "", z: -42, __uf__: [{5, 2, <<121, 97, 121, 101>>}]}

iex> msg |> Msg.unknown_fields()
[{5, 2, <<121, 97, 121, 101>>}]
```

You must always use `unknown_fields/1` as the name of the field
(e.g. `__uf__`) is generated at compile time to avoid collision with the actual
fields of the Protobuf message.

This function returns a list of tuples `{tag, wire_type, bytes}`.


# Unsupported Features

* Protobuf 3 JSON mapping
* groups
* rpc

Furthermore, all options other than `packed` and `default` are ignored.


# Implementation Choices

* Required fields (Protobuf 2): an error is raised when decoding a message with a missing required
  field.

* When decoding enum aliases, the last encountered constant is used.
  For instance, in the following example, `:BAR` is always used if the value `1` is read
  on the wire.
  ```protobuf
  enum E {
    option allow_alias = true;
    FOO = 0;
    BAZ = 1;
    BAR = 1;
  }
  ```

* Unset optionals
  * For Protobuf 2, unset optional fields are mapped to `nil`.
    You can use the generated `default/1` function to get the default value:
    ```elixir
    use Protox,
    schema: """
      syntax = "proto2";

      message Foo {
        optional int32 a = 1 [default = 42];
      }
    """

    iex> Foo.default(:a)
    {:ok, 42}
    ```

  * For Protobuf 3, unset optional fields are mapped to their default values, as mandated by
    the [Protobuf spec](https://developers.google.com/protocol-buffers/docs/proto3#default).

* Messages and enums names: non camel case names are converted using the
  [`Macro.camelize/1`](https://hexdocs.pm/elixir/Macro.html#camelize/1) function.
  Thus, in the following example, `non_camel` becomes `NonCamel`:
  ```protobuf
  syntax = "proto3";

  message non_camel {
  }

  message Camel {
    non_camel x = 1;
  }
  ```

# Types Mapping

The following table shows how Protobuf types are mapped to Elixir ones.

Protobuf   | Elixir
-----------|--------------
int32      | integer()
int64      | integer()
uint32     | integer()
uint64     | integer()
sint32     | integer()
sint64     | integer()
fixed32    | integer()
fixed64    | integer()
sfixed32   | integer()
sfixed64   | integer()
float      | float() \| :infinity \| :'-infinity' \| :nan
double     | float() \| :infinity \| :'-infinity' \| :nan
bool       | boolean()
string     | String.t
bytes      | binary()
map        | %{}
oneof      | {:field, value}
enum       | atom() \| integer()
message    | struct()

# Conformance

The protox library has been tested using the conformance checker provided by Google. Note that only the binary part is tested as protox supports only this format. For instance, JSON tests are skipped.

Here's how to launch the conformance test:

* Get conformance-test-runner [sources](https://github.com/google/protobuf/archive/v3.12.1.tar.gz).
* Compile conformance-test-runner:
  `tar xf protobuf-3.12.1.tar.gz && cd protobuf-3.12.1 && ./autogen.sh && ./configure && make -j && cd conformance && make -j`
* `mix protox.conformance --runner=/path/to/protobuf-3.12.1/conformance/conformance-test-runner`.
  A report will be generated in a directory `conformance_report`.
  If everything's fine, the following text should be displayed:

  ```
CONFORMANCE TEST BEGIN ====================================

CONFORMANCE SUITE PASSED: 1302 successes, 705 skipped, 0 expected failures, 0 unexpected failures.


CONFORMANCE TEST BEGIN ====================================

CONFORMANCE SUITE PASSED: 0 successes, 69 skipped, 0 expected failures, 0 unexpected failures.
  ```

# Credits

Both [gpb](https://github.com/tomas-abrahamsson/gpb) and
[exprotobuf](https://github.com/bitwalker/exprotobuf) were very useful in
understanding how to implement Protocol Buffers.
