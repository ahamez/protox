defmodule Protox.MessageSchemaTest do
  use ExUnit.Case, async: true

  alias ProtobufTestMessages.Proto3.TestAllTypesProto3
  alias Protox.{Field, MessageSchema, OneOf, Scalar}

  @compact_fields [
    {:a, 1, :optional, {:scalar, 0}, :int32},
    {:b, 2, nil, :map, {:string, :int64}},
    {:c, 3, :repeated, :packed, :sint32},
    {:d, 4, :repeated, :unpacked, :string},
    {:child, 5, :optional, {:oneof, :choice}, :uint32},
    {:ext, 6, :optional, {:scalar, :FOO}, {:enum, SomeEnum}, SomeExtender}
  ]

  describe "expand!/4" do
    test "expands every compact kind, with and without extender" do
      schema = MessageSchema.expand!(SomeMessage, :proto3, @compact_fields, %{java_package: "x"})

      assert %MessageSchema{
               name: SomeMessage,
               syntax: :proto3,
               file_options: %{java_package: "x"}
             } = schema

      assert schema.fields == %{
               a: %Field{tag: 1, label: :optional, name: :a, kind: %Scalar{default_value: 0}, type: :int32},
               b: %Field{tag: 2, label: nil, name: :b, kind: :map, type: {:string, :int64}},
               c: %Field{tag: 3, label: :repeated, name: :c, kind: :packed, type: :sint32},
               d: %Field{tag: 4, label: :repeated, name: :d, kind: :unpacked, type: :string},
               child: %Field{
                 tag: 5,
                 label: :optional,
                 name: :child,
                 kind: %OneOf{parent: :choice},
                 type: :uint32
               },
               ext: %Field{
                 tag: 6,
                 label: :optional,
                 name: :ext,
                 kind: %Scalar{default_value: :FOO},
                 type: {:enum, SomeEnum},
                 extender: SomeExtender
               }
             }
    end
  end

  describe "default/2" do
    setup do
      %{schema: MessageSchema.expand!(SomeMessage, :proto3, @compact_fields, nil)}
    end

    test "scalar fields have a default", %{schema: schema} do
      assert MessageSchema.default(schema, :a) == {:ok, 0}
      assert MessageSchema.default(schema, :ext) == {:ok, :FOO}
    end

    test "map, repeated and oneof fields have no default", %{schema: schema} do
      assert MessageSchema.default(schema, :b) == {:error, :no_default_value}
      assert MessageSchema.default(schema, :c) == {:error, :no_default_value}
      assert MessageSchema.default(schema, :d) == {:error, :no_default_value}
      assert MessageSchema.default(schema, :child) == {:error, :no_default_value}
    end

    test "unknown fields are reported", %{schema: schema} do
      assert MessageSchema.default(schema, :nope) == {:error, :no_such_field}
    end
  end

  describe "generated schema/0" do
    test "expands to the same structs as before the compact representation" do
      schema = TestAllTypesProto3.schema()

      assert %MessageSchema{name: TestAllTypesProto3, syntax: :proto3} =
               schema

      assert schema.fields[:optional_int32] ==
               Protox.Field.new!(
                 tag: 1,
                 label: :optional,
                 name: :optional_int32,
                 kind: %Scalar{default_value: 0},
                 type: :int32
               )

      assert schema.fields[:oneof_uint32].kind == %OneOf{parent: :oneof_field}
      assert schema.fields[:map_int32_int32].kind == :map
    end
  end
end
