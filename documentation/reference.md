# Generated code reference

This documentation lists the functions generated with each Elixir structure associated to a protobuf [message](documentation/reference.md#messages) or [enum](documentation/reference.md#enums).

## Messages

### Encode

```elixir
@spec encode(struct() :: {:ok, iodata()} | {:error, any()}
encode(msg)
```

Encode `msg` into an `iodata` suitable for files or sockets.
Returns `{:ok, iodata}` when the encoding was successful and `{:error, description}` in case of an encoding error.


```elixir
@spec encode!(struct() :: iodata() | no_return()
encode!(msg)
```

Throwing version of `encode/1`.

### Decode

```elixir
@spec decode(binary() :: {:ok, struct()} | {:error, any()}
decode(data)
```

Decode binary `data` into an structure with the type of the module on which this function is called.
Returns `{:ok, msg}` when the decoding was successful and `{:error, description}` in case of an decoding error.


```elixir
@spec decode!(binary() :: struct() | no_return()
decode!(data)
```

Throwing version of `decode/1`.

### Default values

```elixir
@spec default(atom() :: {:ok, boolean() | integer() | String.t() | binary() | float()} | {:error, atom()}
default(field_name)
```

Get the default value of a message field. Note that for Protobuf 3, the default value is mandated by [the Google reference documentation](https://developers.google.com/protocol-buffers/docs/proto3#default).

### Unknown fields

```elixir
@spec clear_unknown_fields(struct() :: struct()
clear_unknown_fields(msg)
```
Returns a copy of `msg` with all unknown fields removed.

```elixir
@spec unknown_fields(struct() :: [{non_neg_integer(), Protox.Types.tag(), binary()}]
unknown_fields(msg)
```
Get the unknown fields that may have been encountered when decoding data.
See [Types](documentation/reference.md#types) section to get a description of `Protox.Types.tag`.

```elixir
@spec unknown_fields_name() :: atom()
unknown_fields_name(msg)
```
Get the name of the field that stores unknown fields.

### Metadata
```elixir
@spec schema() :: Protox.MessageSchema.t()
schema()
```
Return the underlying definition of a message, which contains information such as:
- syntax (protobuf 2 or 3)
- required fields
- types of fields

## Enums

```elixir
@spec default() :: atom()
default()
```
Get the default value of an enum.

```elixir
@spec encode(atom() :: integer() | atom()
encode(enum_entry)
```
Get the integer value of an enum entry. If `enum_entry` does not exist in the enum, it is returned as is.


```elixir
@spec decode(integer() :: atom() | integer()
decode(value)
```
Get the enum entry of an integer value. If `value` does not correpond to any entry in the enum, it is returned as is.

```elixir
@spec constants() :: [{integer(), atom()}]
constants()
```
Get the list of all the constants of the enum that correponds to the module on which this function has been called.
