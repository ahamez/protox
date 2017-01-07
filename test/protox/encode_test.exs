defmodule Protox.EncodeTest do
  use ExUnit.Case


  test "empty", %{} do
    assert Protox.Encode.encode(%Sub{}) |> :binary.list_to_bin()
           == <<>>
  end


  test "Sub.a" do
    assert Protox.Encode.encode(%Sub{a: 150}) |> :binary.list_to_bin()
           == <<8, 150, 1>>
  end


  test "Sub.b" do
    assert Protox.Encode.encode(%Sub{b: "testing"}) |> :binary.list_to_bin()
           == <<18, 7, 116, 101, 115, 116, 105, 110, 103>>
  end

  test "Sub.c" do
    assert Protox.Encode.encode(%Sub{c: -300}) |> :binary.list_to_bin()
           == <<48, 212, 253, 255, 255, 255, 255, 255, 255, 255, 1>>
  end


  test "Sub.d; Sub.e" do
    assert Protox.Encode.encode(%Sub{d: 901, e: 433}) |> :binary.list_to_bin()
          == <<56, 133, 7, 64, 177, 3>>
  end


  test "Sub.f" do
    assert Protox.Encode.encode( %Sub{f: -1323}) |> :binary.list_to_bin()
           == <<72, 213, 20>>
  end


  test "Sub.g" do
    assert Protox.Encode.encode(%Sub{g: [1,2]}) |> :binary.list_to_bin()
           == <<106, 16, 1, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0>>
  end


  test "Sub.g, negative" do
    assert Protox.Encode.encode(%Sub{g: [1,-2]}) |> :binary.list_to_bin()
           == <<106, 16, 1, 0, 0, 0, 0, 0, 0, 0, 254, 255, 255, 255, 255, 255, 255, 255>>
  end


  test "Sub.g; Sub.h; Sub.i" do
    assert Protox.Encode.encode(%Sub{g: [0], h: [-1], i: [33.2, -44.0]}) |> :binary.list_to_bin()
          == <<106, 8, 0, 0, 0, 0, 0, 0, 0, 0, 114, 4, 255, 255, 255, 255, 122, 16, 154, 153,
               153, 153, 153, 153, 64, 64, 0, 0, 0, 0, 0, 0, 70, 192>>
  end


  test "Sub.h" do
    assert Protox.Encode.encode(%Sub{h: [-1,-2]}) |> :binary.list_to_bin()
           == <<114, 8, 255, 255, 255, 255, 254, 255, 255, 255>>
  end


  test "Sub.j, unpacked in definition" do
    assert Protox.Encode.encode(%Sub{j: [1, 2, 3]}) |> :binary.list_to_bin()
           == <<128, 1, 1, 128, 1, 2, 128, 1, 3>>
  end


  test "Sub.k; Sub.l" do
    assert Protox.Encode.encode(%Sub{k: 23, l: -99}) |> :binary.list_to_bin()
           == <<141, 1, 23, 0, 0, 0, 145, 1, 157, 255, 255, 255, 255, 255, 255, 255>>
  end


  test "Sub.m, empty" do
    assert Protox.Encode.encode(%Sub{m: <<>>}) |> :binary.list_to_bin()
           == <<>>
  end


  test "Sub.m" do
    assert Protox.Encode.encode(%Sub{m: <<1,2,3>>}) |> :binary.list_to_bin()
           == <<154, 1, 3, 1, 2, 3>>
  end


  test "Sub.n" do
    assert Protox.Encode.encode(%Sub{n: [true, false, false, true]}) |> :binary.list_to_bin()
           == <<162, 1, 4, 1, 0, 0, 1>>
  end


  test "Sub.n (all true)" do
    assert Protox.Encode.encode(%Sub{n: [true, true, true, true]}) |> :binary.list_to_bin()
           == <<162, 1, 4, 1, 1, 1, 1>>
  end


  test "Sub.n (all false)" do
    assert Protox.Encode.encode(%Sub{n: [false, false, false, false]}) |> :binary.list_to_bin()
           == <<162, 1, 4, 0, 0, 0, 0>>
  end


  test "Sub.o " do
    assert Protox.Encode.encode(%Sub{o: [:FOO, :BAR, :FOO]}) |> :binary.list_to_bin()
           == <<170, 1, 3, 0, 1, 0>>
  end


  test "Sub.o (unknown entry) " do
    assert Protox.Encode.encode(%Sub{o: [:FOO, :BAR, :FOO, 2]}) |> :binary.list_to_bin()
           == <<170, 1, 4, 0, 1, 0, 2>>
  end


  test "Sub.p (unpacked in definition) " do
    assert Protox.Encode.encode(%Sub{p: [true, false, true, false]}) |> :binary.list_to_bin()
           == <<176, 1, 1, 176, 1, 0, 176, 1, 1, 176, 1, 0>>
  end


  test "Sub.q (unpacked in definition) " do
    assert Protox.Encode.encode(%Sub{q: [:FOO, :BAR, :BAR, :FOO]}) |> :binary.list_to_bin()
           == <<184, 1, 0, 184, 1, 1, 184, 1, 1, 184, 1, 0>>
  end


  test "Sub.q (unpacked in definition, with unknown values) " do
    assert Protox.Encode.encode(%Sub{q: [:FOO, :BAR, 2, :FOO]}) |> :binary.list_to_bin()
           == <<184, 1, 0, 184, 1, 1, 184, 1, 2, 184, 1, 0>>
  end


  test "Sub.r, negative constant" do
    assert Protox.Encode.encode(%Sub{r: :NEG}) |> :binary.list_to_bin()
           == <<192,1,255,255,255,255,255,255,255,255,255,1,>>
  end


  test "Sub.s, default" do
    assert Protox.Encode.encode(%Sub{s: :ONE}) |> :binary.list_to_bin()
           == <<>>
  end


  test "Sub.s" do
    assert Protox.Encode.encode(%Sub{s: :TWO}) |> :binary.list_to_bin()
           == <<200, 1, 2>>
  end


  test "Sub.t, default is nil" do
    assert Protox.Encode.encode(%Sub{t: nil}) |> :binary.list_to_bin()
           == <<>>
  end


  test "Sub.z" do
    assert Protox.Encode.encode(%Sub{z: -20}) |> :binary.list_to_bin()
           == <<136, 241, 4, 39>>
  end


  test "Sub, unknown fields (double)" do
    assert Protox.Encode.encode(%Sub{
      a: 42,
      b: "",
      z: -42,
      __unknown_fields__: [{3, 1, <<246, 40, 92, 143, 194, 53, 69, 64>>}]})
    |> :binary.list_to_bin()
    == <<8, 42, 136, 241, 4, 83, 25, 246, 40, 92, 143, 194, 53, 69, 64>>
  end


  test "Sub, unknown tag (embedded message)" do
    assert Protox.Encode.encode(%Sub{a: 42, b: "", z: -42, __unknown_fields__: [{4, 2, <<>>}]})
          |> :binary.list_to_bin()
           == <<8, 42, 136, 241, 4, 83, 34, 0>>
  end


  test "Sub, unknown tag (string)" do
    assert Protox.Encode.encode(%Sub{
      a: 42,
      b: "",
      z: -42,
      __unknown_fields__: [{5, 2, <<121, 97, 121, 101>>}]})
    |> :binary.list_to_bin()
    == <<8, 42, 136, 241, 4, 83, 42, 4, 121, 97, 121, 101>>
  end


  test "Sub, unknown tag (bytes)" do
    bytes = Stream.repeatedly(fn -> <<0>> end) |> Enum.take(128) |> Enum.join()
    assert Protox.Encode.encode(%Sub{
      a: 3342,
      b: "",
      z: -10,
      __unknown_fields__: [{10, 2, bytes}]})
    |> :binary.list_to_bin()
    == <<8, 142, 26, 136, 241, 4, 19, 82, 128, 1, bytes::binary>>
  end


  test "Sub, unknown tag (varint + bytes)" do
    assert Protox.Encode.encode(%Sub{
      a: 3342,
      b: "",
      z: -10,
      __unknown_fields__: [
        {11, 0, <<154, 5>>},
        {10, 2, <<104, 101, 121, 33>>}
      ]})
    |> :binary.list_to_bin()
    == <<8, 142, 26, 136, 241, 4, 19, 88, 154, 5, 82, 4, 104, 101, 121, 33>>
  end


  test "Sub, unknown tag (float + varint + bytes)" do
    assert Protox.Encode.encode(%Sub{
      a: 3342,
      b: "",
      z: -10,
      __unknown_fields__: [
        {12, 5, <<236, 81, 5, 66>>},
        {11, 0, <<154, 5>>},
        {10, 2, <<104, 101, 121, 33>>}
      ]}
    )
    |> :binary.list_to_bin()
    == <<8, 142, 26, 136, 241, 4, 19, 101, 236, 81, 5, 66, 88, 154, 5, 82, 4, 104, 101, 121, 33>>
  end


  test "Msg.d, :FOO" do
    assert Protox.Encode.encode(%Msg{d: :FOO}) |> :binary.list_to_bin()
           == <<>>
  end


  test "Msg.d, :BAR" do
    assert Protox.Encode.encode(%Msg{d: :BAR}) |> :binary.list_to_bin()
           == <<8, 1>>
  end


  test "Msg.d, :BAZ" do
    assert Protox.Encode.encode(%Msg{d: :BAZ}) |> :binary.list_to_bin()
           == <<8, 1>>
  end


  test "Msg.d, unknown value" do
    assert Protox.Encode.encode(%Msg{d: 99}) |> :binary.list_to_bin()
           == <<8, 99>>
  end


  test "Msg.e, false" do
    assert Protox.Encode.encode(%Msg{e: false}) |> :binary.list_to_bin()
           == <<>>
  end


  test "Msg.e, true" do
    assert Protox.Encode.encode(%Msg{e: true}) |> :binary.list_to_bin()
           == <<16, 1>>
  end


  test "Msg.f, empty" do
    assert Protox.Encode.encode(%Msg{f: %Sub{}}) |> :binary.list_to_bin()
           == <<26, 0>>
  end


  test "Msg.f.a" do
    assert Protox.Encode.encode(%Msg{f: %Sub{a: 150}}) |> :binary.list_to_bin()
           == <<26, 3, 8, 150, 1>>
  end


  test "Msg.g, empty" do
    assert Protox.Encode.encode(%Msg{g: []}) |> :binary.list_to_bin()
           == <<>>
  end


  test "Msg.g (negative)" do
    assert Protox.Encode.encode(%Msg{g: [1, 2, -3]}) |> :binary.list_to_bin()
           == <<34, 7, 1, 2, 253, 255, 255, 255, 15>>
  end


  test "Msg.g" do
    assert Protox.Encode.encode(%Msg{g: [1, 2, 3]}) |> :binary.list_to_bin()
           == <<34, 3, 1, 2, 3>>
  end


  test "Msg.h, empty" do
    assert Protox.Encode.encode(%Msg{h: 0.0}) |> :binary.list_to_bin()
           == <<>>
  end


  test "Msg.h" do
    assert Protox.Encode.encode(%Msg{h: -43.2}) |> :binary.list_to_bin()
           == <<41, 154, 153, 153, 153, 153, 153, 69, 192>>
  end


  test "Msg.i" do
    assert Protox.Encode.encode(%Msg{i: [2.3, -4.2]}) |> :binary.list_to_bin()
           == <<50, 8, 51, 51, 19, 64, 102, 102, 134, 192>>
  end


  test "Msg.j" do
    assert Protox.Encode.encode(%Msg{j: [%Sub{a: 42}, %Sub{b: "foo"}]}) |> :binary.list_to_bin()
           == <<58, 2, 8, 42, 58, 5, 18, 3, 102, 111, 111>>
  end


  test "Msg.k" do
    assert Protox.Encode.encode(%Msg{k: %{1 => "foo", 2 => "bar"}}) |> :binary.list_to_bin()
           == <<66, 7, 8, 1, 18, 3, 102, 111, 111, 66, 7, 8, 2, 18, 3, 98, 97, 114>>
  end


  test "Msg.l" do
    assert Protox.Encode.encode(%Msg{l: %{"bar" => 1.0, "foo" => 43.2}}) |> :binary.list_to_bin()
           == <<74, 14, 10, 3, 98, 97, 114, 17, 0, 0, 0, 0, 0, 0, 240, 63, 74, 14, 10, 3, 102,
                111, 111, 17, 154, 153, 153, 153, 153, 153, 69, 64>>
  end


  test "Msg.m, string" do
    assert Protox.Encode.encode(%Msg{m: {:n, "bar"}}) |> :binary.list_to_bin()
           == <<82, 3, 98, 97, 114>>
  end


  test "Msg.m, Sub" do
    assert Protox.Encode.encode(%Msg{m: {:o, %Sub{a: 42}}}) |> :binary.list_to_bin()
           == <<90, 2, 8, 42>>
  end


  test "Msg.p" do
    assert Protox.Encode.encode(%Msg{p: %{1 => :BAR}}) |> :binary.list_to_bin()
           == <<98, 4, 8, 1, 16, 1>>
  end


  test "Msg.q" do
    assert Protox.Encode.encode(%Msg{q: :BAZ}) |> :binary.list_to_bin()
           == <<>>
  end


  test "Msg.oneof_double" do
    assert Protox.Encode.encode(%Msg{oneof_field: {:oneof_double, 0}}) |> :binary.list_to_bin()
           == <<177,7,0,0,0,0,0,0,0,0,>>
  end


  test "Empty" do
    assert Protox.Encode.encode(%Empty{}) |> :binary.list_to_bin()
           == <<>>
  end


  test "Upper.empty" do
    assert Protox.Encode.encode(%Upper{empty: %Empty{}}) |> :binary.list_to_bin()
           == <<26, 0>>
  end

end
