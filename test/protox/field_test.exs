defmodule Protox.FieldTest do
  use ExUnit.Case

  alias Protox.{Field, IllegalTagError, InvalidFieldAttribute}

  describe "json_name" do
    test "default to lower camel case of name" do
      f1 = Field.new!(tag: 1, name: :foo_bar, kind: {:scalar, 0}, type: :int32)
      assert f1.json_name == "fooBar"

      f2 = Field.new!(tag: 1, name: :foo, kind: {:scalar, 0}, type: :int32)
      assert f2.json_name == "foo"
    end

    test "can override with a value" do
      f = Field.new!(tag: 1, name: :foo, kind: {:scalar, 0}, type: :int32, json_name: "bar")

      assert f.json_name == "bar"
    end

    test "can use a function" do
      f =
        Field.new!(
          tag: 1,
          name: :a,
          kind: {:scalar, 0},
          type: :int32,
          json_name: fn _ -> "b" end
        )

      assert f.json_name == "b"
    end
  end

  describe "errors" do
    test "can't construct with tag == 0" do
      assert_raise IllegalTagError, fn ->
        Field.new!(tag: 0, name: :foo, kind: {:scalar, 0}, type: :int32)
      end
    end

    test "can't construct with invalid label" do
      assert_raise InvalidFieldAttribute, fn ->
        Field.new!(tag: 1, label: :invalid_label, name: :foo, kind: {:scalar, 0}, type: :int32)
      end
    end
  end
end
