# Migration guide (v1 to v2)

This guide explains how to migrate from version 1 to version 2 of Protox.

> [!NOTE]
> You'll find the rationales behind the changes in the [changelog](../CHANGELOG.md).

## Encoding

Protox now returns the size of the encoded messages along with the encoded data. If you don't need the size, you can simply ignore it:

```elixir
iex> msg = %Foo{a: 3, b: %{1 => %Baz{}}}
{:ok, iodata, _iodata_size} = Protox.encode(msg)
```

## JSON support

It's no longer possible to encode or decode JSON data directly using Protox. If it's necessary, you can stick to version 1.7 or switch to [`protobuf`](https://hex.pm/packages/protobuf).

## `Protox` macro options

The `:path` option is removed in favor of the already existing `:paths` option, thus one just has to provide a list containing a single path.

Also, the `:keep_unknown_fields` option is no longer available. Thus, unknown fields are always kept. If you don't need them, you can simply ignore them.

## Generated code

The following functions generated for messages are replaced by the function `schema/0`:

- `defs/0`
- `field_def/1`
- `file_options/0`
- `required_fields/0`
- `syntax/0`

`schema/0` returns a `Protox.MessageSchema` struct which contains information about the message's fields, syntax, and file options.

### Example

```elixir
iex> defmodule MyModule do
  use Protox, schema: """
  syntax = "proto2";

  message Foo {
    required int32 a = 1;
    map<int32, string> b = 2;
  }
  """
end

iex> Foo.schema().syntax
:proto2

iex> Foo.schema().fields[:a]
%Protox.Field{
  tag: 1,
  label: :required,
  name: :a,
  kind: %Protox.Scalar{default_value: 0},
  type: :int32
}

iex> Foo.schema().file_options
nil
```
