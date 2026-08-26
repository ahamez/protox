defmodule Protox.GuardsTest do
  use ExUnit.Case, async: true

  import Protox.Guards

  test "is_primitive" do
    assert is_primitive(:int32) == true
    assert is_primitive(:foo) == false
  end

  test "is_primitive_varint" do
    assert is_primitive_varint(:int32) == true
    assert is_primitive_varint(:foo) == false
  end

  test "is_primitive_fixed32" do
    assert is_primitive_fixed32(:fixed32) == true
    assert is_primitive_fixed32(:int32) == false
  end

  test "is_primitive_fixed64" do
    assert is_primitive_fixed64(:fixed64) == true
    assert is_primitive_fixed64(:int32) == false
  end

  test "is_delimited" do
    assert is_delimited(:string) == true
    assert is_delimited(:bytes) == true
    assert is_delimited(:int32) == false
  end
end
