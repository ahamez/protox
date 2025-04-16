# Types mapping

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
`oneof`    | `{atom(), value_type}` where `atom()` is the name of the set field and where `value_type` is the type of the set field
`enum`     | `atom() \| integer()`
`message`  | `struct()`
