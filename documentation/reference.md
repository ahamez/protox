# Generated code reference

## Messages

### Encode

```elixir
@spec(encode(struct) :: {:ok, iodata} | {:error, any})
encode(msg)
```

Encode `msg` into an `iodata` suitable for files or sockets.
Returns `{:ok, iodata}` when the encoding was successful and `{:error, description}` in case of an encoding error.


```elixir
@spec(encode!(struct) :: iodata | no_return)
encode!(msg)
```

Throwing version of `encode/1`.

### Decode

```elixir
@spec(decode(binary) :: {:ok, struct} | {:error, any})
decode(data)
```

Decode binary `data` into an structure with the type of the module on which this function is called.
Returns `{:ok, msg}` when the decoding was successful and `{:error, description}` in case of an decoding error.


```elixir
@spec(decode!(binary) :: struct | no_return)
decode!(data)
```

Throwing version of `decode/1`.

### Syntax and definitions

```elixir
@spec(syntax() :: atom)
syntax()
```
Get the syntax of the protobuf message: `:proto2` or `:proto3`.

```elixir
@spec defs() :: %{required(non_neg_integer) => {atom, Protox.Types.kind(), Protox.Types.type()}}
defs()
```
Get the underlying definition of a protobuf message, mostly used for internal usage.
See [Types]("#types") section to get a description of `Protox.Types.kind` and `Protox.Types.type`.

```elixir
@spec %{required(atom) => {non_neg_integer, Protox.Types.kind(), Protox.Types.type()}}
defs_by_name()
```
Get the underlying definition of a protobuf message, mostly used for internal usage.
See [Types]("#types") section to get a description of `Protox.Types.kind` and `Protox.Types.type`.

### Default values

```elixir
@spec(default(atom) :: {:ok, boolean | integer | String.t() | binary | float} | {:error, atom}
default(field_name)
```

Get the default value of a structure field. Note that for Protobuf 3, the default value is mandated by [the Google reference documentation](https://developers.google.com/protocol-buffers/docs/proto3#default).

### Unknown fields

```elixir
@spec clear_unknown_fields(struct) :: struct
clear_unknown_fields(msg)
```
Remove all unknown fields of `msg`.

```elixir
@spec unknown_fields(struct) :: [{non_neg_integer, Protox.Types.tag(), binary}]
unknown_fields(msg)
```
Get the unknown fields that may have been encountered when decoding data.
See [Types]("#types") section to get a description of `Protox.Types.tag`.

```elixir
@spec unknown_fields_name() :: atom
unknown_fields_name(msg)
```
Get the name of the field that stored the potential unknown fields.


```elixir
@spec required_fields() :: [atom]
required_fields()
```

## Enums

```elixir
@spec default() :: atom
default()
```
Get the default value of an enum.

```elixir
@spec encode(atom) :: integer | atom
encode(enum_entry)
```
Get the integer value of an enum entry. If `enum_entry` does not exist in the enum, it is returned as is.


```elixir
@spec decode(integer) :: atom | integer
decode(value)
```
Get the enum entry of an integer value. If `value` does not correpond to any entry in the enum, it is returned as is.

```elixir
@spec constants() :: [{integer, atom}]
constants()
```
Get the list of all the constants of the enum that correponds to the module on which this function has been called.

## Types

Types `Protox.Types.tag`, `Protox.Types.kind` and `Protox.Types.type` are defined as follows
(see [here](https://developers.google.com/protocol-buffers/docs/encoding#structure) for more details):

```elixir
@type wire_varint :: 0
@type wire_64bits :: 1
@type wire_delimited :: 2
@type wire_32bits :: 5

@type tag :: wire_varint | wire_64bits | wire_delimited | wire_32bits
@type kind :: {:default, any} | :packed | :unpacked | :map | {:oneof, atom}
@type map_key_type ::
        :int32
        | :int64
        | :uint32
        | :uint64
        | :sint32
        | :sint64
        | :fixed32
        | :fixed64
        | :sfixed32
        | :sfixed64
        | :bool
        | :string
@type type ::
        :fixed32
        | :sfixed32
        | :float
        | :fixed64
        | :sfixed64
        | :double
        | :int32
        | :uint32
        | :sint32
        | :int64
        | :uint64
        | :sint64
        | :bool
        | :string
        | :bytes
        | {:enum, atom}
        | {:message, atom}
        | {map_key_type, type}

```