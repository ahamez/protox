defmodule Protox.FieldTest do
  use ExUnit.Case

  alias Protox.{Field, IllegalTagError, InvalidFieldAttribute}

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
