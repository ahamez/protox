# Protox

[![Build Status](https://travis-ci.org/ahamez/protox.svg?branch=master)](https://travis-ci.org/ahamez/protox) [![Coverage Status](https://coveralls.io/repos/github/ahamez/protox/badge.svg?branch=master)](https://coveralls.io/github/ahamez/protox?branch=master) [![Hex.pm Version](http://img.shields.io/hexpm/v/protox.svg)](https://hex.pm/packages/protox) [![Deps Status](https://beta.hexfaktor.org/badge/prod/github/ahamez/protox.svg)](https://beta.hexfaktor.org/github/ahamez/protox) [![Inline docs](http://inch-ci.org/github/ahamez/protox.svg)](http://inch-ci.org/github/ahamez/protox) [![Ebert](https://ebertapp.io/github/ahamez/protox.svg)](https://ebertapp.io/github/ahamez/protox)


Protox is an Elixir library to work with Google's Protocol Buffers (version 2 and 3).


# Prerequisites

Protox uses Google's `protoc` (>= 3.0) to parse `.proto` files. It must be available in `$PATH`.
You can get it [here](https://github.com/google/protobuf).


# Usage

From files:

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

From a textual description:

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

The previous example will generate two modules: `Fiz.Baz` and `Fiz.Foo`.

It's possible to prepend a namespace to all generated modules:

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

In this case, the module `Namespace.Enum` will be generated.


Here's how to create a new message:

```elixir
iex> %Fiz.Foo{a: 3, b: %{1 => %Fiz.Baz{}}} |> Protox.Encode.encode()
[[[], "\b", <<3>>], <<18>>, <<4>>, "\b", <<1>>, <<18>>, <<0>>]
```

Note that `Protox.Encode.encode/1` creates an iolist, not a binary. Such iolists can be used
directly with files or sockets read/write operations.
However, you can use `:binary.list_to_bin/1` to get a binary:

```elixir
iex> %Fiz.Foo{a: 3, b: %{1 => %Fiz.Baz{}}} |> Protox.Encode.encode() |> :binary.list_to_bin()
<<8, 3, 18, 4, 8, 1, 18, 0>>
```

Finally, here's how to decode:

```elixir
iex> <<8, 3, 18, 4, 8, 1, 18, 0>> |> Fiz.Foo.decode()
{:ok, %Fiz.Foo{a: 3, b: %{1 => %Fiz.Baz{}}}}
```


# Unknown fields

If any unknown fields are encountered when decoding, they are kept in the decoded message.
It's possible to access them with the function `unknown_fields/1` defined with the message.

```elixir
iex> msg = <<8, 42, 42, 4, 121, 97, 121, 101, 136, 241, 4, 83>> |> Msg.decode!()
%Msg{a: 42, b: "", z: -42, __unknown_fields__: [{5, 2, <<121, 97, 121, 101>>}]}

iex> Msg.unknown_fields(msg)
[{5, 2, <<121, 97, 121, 101>>}]
```

You should always use `unknown_fields/1` as the name of the struct field
(e.g. `__unknown_fields__`) is generated at compile-time to avoid collision with the actual
fields of the protobuf message.

It returns a list of tuples `{tag, wire_type, bytes}`.


# Unsupported features

* protobuf 3 JSON mapping
* groups
* rpc

Furthermore, all options other than `packed` and `default` are ignored.


# Implementation choices

* Required fields (protobuf 2): an error is raised when decoding a message with a missing required
  field.

* When decoding enum aliases, the last encountered constant will be used.
  For instance, in the following example, `:BAR` will always be used if the value `1` is read
  on the wire.
  ```
  enum E {
    option allow_alias = true;
    FOO = 0;
    BAZ = 1;
    BAR = 1;
  }
  ```

* Unset optionals
  * For protobuf 2, unset optional fields are mapped to `nil`
  * For protobuf 3, unset optional fields are mapped to their default values, as mandated by
    the protobuf spec


# Types mapping

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
float      | float()
double     | float()
bool       | boolean()
string     | String.t
bytes      | binary()
map        | %{}
oneof      | {:field, value}
enum       | atom()
message    | struct()


# Performance

TODO. Do some benchmarks.

# Conformance

This library has been tested using the conformance checker provided by Google.
Note that only the protobuf part is tested: as protox doesn't support JSON
output, the corresponding tests are skipped.

Here's how to launch the conformance test:

* Get conformance-test-runner (https://github.com/google/protobuf/tree/master/conformance)
* `mix protox.conformance --runner=/path/to/conformance-test-runner`
  A report will be generated in a file named `conformance_report.txt`.
  If everything's fine, something like the following should be displayed:

  ```
  CONFORMANCE TEST BEGIN ====================================

  CONFORMANCE SUITE PASSED: 149 successes, 384 skipped, 0 expected failures, 0 unexpected failures.
  ```


# Credits

Both [gpb](https://github.com/tomas-abrahamsson/gpb) and
[exprotobuf](https://github.com/bitwalker/exprotobuf) were very useful in
understanding how to implement Protocol Buffers.
