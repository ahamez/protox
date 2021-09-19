defmodule Protox.DefineTest do
  use ExUnit.Case

  use Protox,
    schema: """
      syntax = "proto3";

      message DefineEmpty3 {
      }

      message DefineFoo3 {
        DefineFoo3Enum a = 1;
        map<int32, string> b = 2;
        int32 c = 3;
        DefineEmpty3 d = 4;
      }

      enum DefineFoo3Enum {
        FOO = 0;
        BAR = 1;
      }
    """

  use Protox,
    schema: """
      syntax = "proto2";

      message DefineFoo2 {
        required int32 a = 1 [default = 1];
        required int32 b = 2;
        optional DefineFoo2Enum c = 3;
        optional bool d = 4 [default = true];
        optional bool e = 5 [default = false];
        optional DefineFoo2Enum f = 6 [default = BAR];
      }

      enum DefineFoo2Enum {
        FOO = 1;
        BAR = 2;
      }
    """

  describe "Default values" do
    test "Protobuf3" do
      assert DefineFoo3.default(:a) == {:ok, :FOO}
      assert DefineFoo3.default(:b) == {:error, :no_default_value}
      assert DefineFoo3.default(:c) == {:ok, 0}
      assert DefineFoo3.default(:d) == {:ok, nil}
      assert DefineFoo3.default(:e) == {:error, :no_such_field}
    end

    test "Protobuf2" do
      assert DefineFoo2.default(:a) == {:ok, 1}
      assert DefineFoo2.default(:b) == {:ok, 0}
      assert DefineFoo2.default(:c) == {:ok, :FOO}
      assert DefineFoo2.default(:d) == {:ok, true}
      assert DefineFoo2.default(:e) == {:ok, false}
      assert DefineFoo2.default(:f) == {:ok, :BAR}
    end
  end

  describe "Fields" do
    test "Get all fields" do
      fields = DefineFoo3.fields_defs()
      assert length(fields) != 0

      assert fields == [
               %Protox.Field{
                 json_name: "a",
                 kind: {:scalar, :FOO},
                 label: :optional,
                 name: :a,
                 tag: 1,
                 type: {:enum, DefineFoo3Enum}
               },
               %Protox.Field{
                 json_name: "b",
                 kind: :map,
                 label: nil,
                 name: :b,
                 tag: 2,
                 type: {:int32, :string}
               },
               %Protox.Field{
                 json_name: "c",
                 kind: {:scalar, 0},
                 label: :optional,
                 name: :c,
                 tag: 3,
                 type: :int32
               },
               %Protox.Field{
                 json_name: "d",
                 kind: {:scalar, nil},
                 label: :optional,
                 name: :d,
                 tag: 4,
                 type: {:message, DefineEmpty3}
               }
             ]
    end

    test "By field name" do
      assert DefineFoo3.field_def(:a) ==
               {:ok,
                %Protox.Field{
                  json_name: "a",
                  kind: {:scalar, :FOO},
                  label: :optional,
                  name: :a,
                  tag: 1,
                  type: {:enum, DefineFoo3Enum}
                }}
    end

    test "By field json_name" do
      assert DefineFoo3.field_def("a") ==
               {:ok,
                %Protox.Field{
                  json_name: "a",
                  kind: {:scalar, :FOO},
                  label: :optional,
                  name: :a,
                  tag: 1,
                  type: {:enum, DefineFoo3Enum}
                }}
    end
  end
end
