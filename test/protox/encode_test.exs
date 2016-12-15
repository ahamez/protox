defmodule Protox.EncodeTest do
  use ExUnit.Case

  test "empty", %{} do
    assert Sub.encode(%Sub{}) == <<>>
  end


  test "Sub.a" do
    assert Sub.encode(%Sub{a: 150})
           == <<8, 150, 1>>
  end


  test "Sub.b" do
    assert Sub.encode(%Sub{b: "testing"})
           == <<18, 7, 116, 101, 115, 116, 105, 110, 103>>
  end


  test "Sub.j, unpacked in definition" do
    assert Sub.encode(%Sub{j: [1, 2, 3]})
           == <<128, 1, 1, 128, 1, 2, 128, 1, 3>>
  end


  test "Sub.z" do
    assert Protox.Encode.encode(%Sub{z: -20})
           == <<136, 241, 4, 39>>
  end


  test "Msg.d, :FOO" do
    assert Protox.Encode.encode(%Msg{d: :FOO})
           == <<>>
  end


  test "Msg.d, :BAR" do
    assert Protox.Encode.encode(%Msg{d: :BAR})
           == <<8, 1>>
  end


  test "Msg.d, unknown value" do
    assert Protox.Encode.encode(%Msg{d: 99})
           == "\bc"
  end


  test "Msg.e, false" do
    assert Protox.Encode.encode(%Msg{e: false})
           == <<>>
  end


  test "Msg.e, true" do
    assert Protox.Encode.encode(%Msg{e: true})
           == <<16, 1>>
  end


  test "Msg.f, empty" do
    assert Protox.Encode.encode(%Msg{f: %Sub{}})
           == <<26, 0>>
  end


  test "Msg.f.a" do
    assert Protox.Encode.encode(%Msg{f: %Sub{a: 150}})
           == <<26, 3, 8, 150, 1>>
  end


  test "Msg.g, empty" do
    assert Protox.Encode.encode(%Msg{g: []})
           == <<>>
  end


  test "Msg.g (negative)" do
    assert Protox.Encode.encode(%Msg{g: [1, 2, -3]})
           == <<34, 12, 1, 2, 253, 255, 255, 255, 255, 255, 255, 255, 255, 1>>
  end


  test "Msg.g" do
    assert Protox.Encode.encode(%Msg{g: [1, 2, 3]})
           == <<34, 3, 1, 2, 3>>
  end


  test "Msg.h, empty" do
    assert Protox.Encode.encode(%Msg{h: 0.0})
           == <<>>
  end


  test "Msg.h" do
    assert Protox.Encode.encode(%Msg{h: -43.2})
           == <<41, 154, 153, 153, 153, 153, 153, 69, 192>>
  end


  test "Msg.i" do
    assert Protox.Encode.encode(%Msg{i: [2.3, -4.2]})
           == <<50, 8, 51, 51, 19, 64, 102, 102, 134, 192>>
  end


  test "Msg.j" do
    assert Protox.Encode.encode(%Msg{j: [%Sub{a: 42}, %Sub{b: "foo"}]})
           == <<58, 2, 8, 42, 58, 5, 18, 3, 102, 111, 111>>
  end


  test "Msg.k" do
    assert Protox.Encode.encode(%Msg{k: %{1 => "foo", 2 => "bar"}})
           == <<66, 7, 8, 1, 18, 3, 102, 111, 111, 66, 7, 8, 2, 18, 3, 98, 97, 114>>
  end


  test "Msg.l" do
    assert %Msg{l: %{"bar" => 1.0, "foo" => 43.2}}
           |> Protox.Encode.encode()
           == <<74, 14, 10, 3, 98, 97, 114, 17, 0, 0, 0, 0, 0, 0, 240, 63, 74, 14, 10, 3, 102,
                111, 111, 17, 154, 153, 153, 153, 153, 153, 69, 64>>
  end


  test "Msg.m, string" do
    assert %Msg{m: {:n, "bar"}} |> Protox.Encode.encode()
           == <<82, 3, 98, 97, 114>>
  end


  test "Msg.m, Sub" do
    assert %Msg{m: {:o, %Sub{a: 42}}} |> Protox.Encode.encode()
           == <<90, 2, 8, 42>>
  end

end
