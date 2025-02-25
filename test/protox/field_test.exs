defmodule Protox.FieldTest do
  use ExUnit.Case

  alias Protox.{Field, IllegalTagError, InvalidFieldAttributeError, Scalar}

  describe "errors" do
    test "can't construct with tag == 0" do
      assert_raise IllegalTagError, fn ->
        Field.new!(tag: 0, name: :foo, kind: %Scalar{default_value: 0}, type: :int32)
      end
    end

    test "can't construct with invalid label" do
      assert_raise InvalidFieldAttributeError, fn ->
        Field.new!(
          tag: 1,
          label: :invalid_label,
          name: :foo,
          kind: %Scalar{default_value: 0},
          type: :int32
        )
      end
    end
  end
end
