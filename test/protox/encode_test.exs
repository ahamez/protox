defmodule Protox.EncodeTest do
  use ExUnit.Case

  test "empty", %{} do
    assert Protox.Encode.encode_binary(%Sub{z: 0}) == <<>>
  end


  test "Sub.a" do
    assert Protox.Encode.encode_binary(%Sub{a: 150, z: 0})
           == <<8, 150, 1>>
  end


  test "Sub.b" do
    assert Protox.Encode.encode_binary(%Sub{b: "testing", z: 0})
           == <<18, 7, 116, 101, 115, 116, 105, 110, 103>>
  end

  test "Sub.c" do
    assert Protox.Encode.encode_binary(%Sub{c: -300, z: 0}) ==\
           <<48, 212, 253, 255, 255, 255, 255, 255, 255, 255, 1>>
  end


  test "Sub.d; Sub.e" do
    assert Protox.Encode.encode_binary(%Sub{d: 901, e: 433, z: 0}) ==\
           <<56, 133, 7, 64, 177, 3>>
  end


  test "Sub.f" do
    assert Protox.Encode.encode_binary( %Sub{f: -1323, z: 0}) ==\
           <<72, 213, 20>>
  end


  test "Sub.g" do
    assert Protox.Encode.encode_binary(%Sub{g: [1,2], z: 0}) ==\
           <<106, 16, 1, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0>>
  end


  test "Sub.g, negative" do
    assert Protox.Encode.encode_binary(%Sub{g: [1,-2], z: 0}) ==\
           <<106, 16, 1, 0, 0, 0, 0, 0, 0, 0, 254, 255, 255, 255, 255, 255, 255, 255>>
  end


  test "Sub.g; Sub.h; Sub.i" do
    assert Protox.Encode.encode_binary(%Sub{g: [0], h: [-1], i: [33.2, -44.0], z: 0}) ==\
           <<106, 8, 0, 0, 0, 0, 0, 0, 0, 0, 114, 4, 255, 255, 255, 255, 122, 16, 154, 153,
             153, 153, 153, 153, 64, 64, 0, 0, 0, 0, 0, 0, 70, 192>>
  end


  test "Sub.h" do
    assert Protox.Encode.encode_binary(%Sub{h: [-1,-2], z: 0}) ==\
            <<114, 8, 255, 255, 255, 255, 254, 255, 255, 255>>
  end


  test "Sub.j, unpacked in definition" do
    assert Protox.Encode.encode_binary(%Sub{j: [1, 2, 3], z: 0})
           == <<128, 1, 1, 128, 1, 2, 128, 1, 3>>
  end


  test "Sub.k; Sub.l" do
    assert Protox.Encode.encode_binary(%Sub{k: 23, l: -99, z: 0})
           == <<141, 1, 23, 0, 0, 0, 145, 1, 157, 255, 255, 255, 255, 255, 255, 255>>
  end


  test "Sub.m, empty" do
    assert Protox.Encode.encode_binary(%Sub{m: <<>>, z: 0})
           == <<>>
  end


  test "Sub.m" do
    assert Protox.Encode.encode_binary(%Sub{m: <<1,2,3>>, z: 0})
           == <<154, 1, 3, 1, 2, 3>>
  end


  test "Sub.n" do
    assert Protox.Encode.encode_binary(%Sub{n: [true, false, false, true], z: 0}) ==\
           <<162, 1, 4, 1, 0, 0, 1>>
  end


  test "Sub.n (all true)" do
    assert Protox.Encode.encode_binary(%Sub{n: [true, true, true, true], z: 0}) ==\
           <<162, 1, 4, 1, 1, 1, 1>>
  end


  test "Sub.n (all false)" do
    assert Protox.Encode.encode_binary(%Sub{n: [false, false, false, false], z: 0}) ==\
           <<162, 1, 4, 0, 0, 0, 0>>
  end


  test "Sub.o " do
    assert Protox.Encode.encode_binary(%Sub{o: [:FOO, :BAR, :FOO], z: 0, z: 0}) ==\
           <<170, 1, 3, 0, 1, 0>>
  end


  test "Sub.o (unknown entry) " do
    assert Protox.Encode.encode_binary(%Sub{o: [:FOO, :BAR, :FOO, 2], z: 0, z: 0}) ==\
           <<170, 1, 4, 0, 1, 0, 2>>
  end


  test "Sub.p (unpacked in definition) " do
    assert Protox.Encode.encode_binary(%Sub{p: [true, false, true, false], z: 0}) ==\
           <<176, 1, 1, 176, 1, 0, 176, 1, 1, 176, 1, 0>>
  end


  test "Sub.q (unpacked in definition) " do
    assert Protox.Encode.encode_binary(%Sub{q: [:FOO, :BAR, :BAR, :FOO], z: 0}) ==\
           <<184, 1, 0, 184, 1, 1, 184, 1, 1, 184, 1, 0>>
  end


  test "Sub.q (unpacked in definition, with unknown values) " do
    assert Protox.Encode.encode_binary(%Sub{q: [:FOO, :BAR, 2, :FOO], z: 0}) ==\
           <<184, 1, 0, 184, 1, 1, 184, 1, 2, 184, 1, 0>>
  end


  test "Sub.z" do
    assert Protox.Encode.encode_binary(%Sub{z: -20})
           == <<136, 241, 4, 39>>
  end


  test "Msg.d, :FOO" do
    assert Protox.Encode.encode_binary(%Msg{d: :FOO})
           == <<>>
  end


  test "Msg.d, :BAR" do
    assert Protox.Encode.encode_binary(%Msg{d: :BAR})
           == <<8, 1>>
  end


  test "Msg.d, :BAZ" do
    assert Protox.Encode.encode_binary(%Msg{d: :BAZ})
           == <<8, 1>>
  end


  test "Msg.d, unknown value" do
    assert Protox.Encode.encode_binary(%Msg{d: 99})
           == <<8, 99>>
  end


  test "Msg.e, false" do
    assert Protox.Encode.encode_binary(%Msg{e: false})
           == <<>>
  end


  test "Msg.e, true" do
    assert Protox.Encode.encode_binary(%Msg{e: true})
           == <<16, 1>>
  end


  test "Msg.f, empty" do
    assert Protox.Encode.encode_binary(%Msg{f: %Sub{z: 0}})
           == <<26, 0>>
  end


  test "Msg.f.a" do
    assert Protox.Encode.encode_binary(%Msg{f: %Sub{a: 150, z: 0}})
           == <<26, 3, 8, 150, 1>>
  end


  test "Msg.g, empty" do
    assert Protox.Encode.encode_binary(%Msg{g: []})
           == <<>>
  end


  test "Msg.g (negative)" do
    assert Protox.Encode.encode_binary(%Msg{g: [1, 2, -3]})
           == <<34, 12, 1, 2, 253, 255, 255, 255, 255, 255, 255, 255, 255, 1>>
  end


  test "Msg.g" do
    assert Protox.Encode.encode_binary(%Msg{g: [1, 2, 3]})
           == <<34, 3, 1, 2, 3>>
  end


  test "Msg.h, empty" do
    assert Protox.Encode.encode_binary(%Msg{h: 0.0})
           == <<>>
  end


  test "Msg.h" do
    assert Protox.Encode.encode_binary(%Msg{h: -43.2})
           == <<41, 154, 153, 153, 153, 153, 153, 69, 192>>
  end


  test "Msg.i" do
    assert Protox.Encode.encode_binary(%Msg{i: [2.3, -4.2]})
           == <<50, 8, 51, 51, 19, 64, 102, 102, 134, 192>>
  end


  test "Msg.j" do
    assert Protox.Encode.encode_binary(%Msg{j: [%Sub{a: 42, z: 0}, %Sub{b: "foo", z: 0}]})
           == <<58, 2, 8, 42, 58, 5, 18, 3, 102, 111, 111>>
  end


  test "Msg.k" do
    assert Protox.Encode.encode_binary(%Msg{k: %{1 => "foo", 2 => "bar"}})
           == <<66, 7, 8, 1, 18, 3, 102, 111, 111, 66, 7, 8, 2, 18, 3, 98, 97, 114>>
  end


  test "Msg.l" do
    assert %Msg{l: %{"bar" => 1.0, "foo" => 43.2}}
           |> Protox.Encode.encode_binary()
           == <<74, 14, 10, 3, 98, 97, 114, 17, 0, 0, 0, 0, 0, 0, 240, 63, 74, 14, 10, 3, 102,
                111, 111, 17, 154, 153, 153, 153, 153, 153, 69, 64>>
  end


  test "Msg.m, string" do
    assert %Msg{m: {:n, "bar"}} |> Protox.Encode.encode_binary()
           == <<82, 3, 98, 97, 114>>
  end


  test "Msg.m, Sub" do
    assert %Msg{m: {:o, %Sub{a: 42, z: 0}}} |> Protox.Encode.encode_binary()
           == <<90, 2, 8, 42>>
  end


  test "Msg.p" do
    assert %Msg{p: %{1 => :BAR}} |> Protox.Encode.encode_binary()
           == <<98, 4, 8, 1, 16, 1>>
  end


  test "Msg.q" do
    assert %Msg{q: :BAZ} |> Protox.Encode.encode_binary()
           == <<>>
  end


  test "Msg.oneof_double" do
    assert Protox.Encode.encode_binary(%Msg{oneof_field: {:oneof_double, 0}})
           == <<177,7,0,0,0,0,0,0,0,0,>>
  end


  test "Empty" do
    assert %Empty{} |> Protox.Encode.encode_binary()
           == <<>>
  end


  test "Upper.empty" do
    assert %Upper{empty: %Empty{}} |> Protox.Encode.encode_binary()
           == <<26, 0>>
  end

end
