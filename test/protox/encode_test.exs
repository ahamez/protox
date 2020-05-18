defmodule Protox.EncodeTest do
  use ExUnit.Case

  test "empty", %{} do
    assert %Sub{} |> Protox.Encode.encode() |> :binary.list_to_bin() == <<>>
  end

  test "Sub.a" do
    assert %Sub{a: 150} |> Protox.Encode.encode() |> :binary.list_to_bin() == <<8, 150, 1>>
  end

  test "Sub.a, negative" do
    assert %Sub{a: -150} |> Protox.Encode.encode() |> :binary.list_to_bin() ==
             <<8, 234, 254, 255, 255, 15>>
  end

  test "Sub.b" do
    assert %Sub{b: "testing"} |> Protox.Encode.encode() |> :binary.list_to_bin() ==
             <<18, 7, 116, 101, 115, 116, 105, 110, 103>>
  end

  test "Sub.c" do
    assert %Sub{c: -300} |> Protox.Encode.encode() |> :binary.list_to_bin() ==
             <<48, 212, 253, 255, 255, 255, 255, 255, 255, 255, 1>>
  end

  test "Sub.d; Sub.e" do
    assert %Sub{d: 901, e: 433} |> Protox.Encode.encode() |> :binary.list_to_bin() ==
             <<56, 133, 7, 64, 177, 3>>
  end

  test "Sub.f" do
    assert %Sub{f: -1323} |> Protox.Encode.encode() |> :binary.list_to_bin() == <<72, 213, 20>>
  end

  test "Sub.g" do
    assert %Sub{g: [1, 2]} |> Protox.Encode.encode() |> :binary.list_to_bin() ==
             <<106, 16, 1, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0>>
  end

  test "Sub.g, negative" do
    assert %Sub{g: [1, -2]} |> Protox.Encode.encode() |> :binary.list_to_bin() ==
             <<106, 16, 1, 0, 0, 0, 0, 0, 0, 0, 254, 255, 255, 255, 255, 255, 255, 255>>
  end

  test "Sub.g; Sub.h; Sub.i" do
    assert %Sub{g: [0], h: [-1], i: [33.2, -44.0]}
           |> Protox.Encode.encode()
           |> :binary.list_to_bin() ==
             <<106, 8, 0, 0, 0, 0, 0, 0, 0, 0, 114, 4, 255, 255, 255, 255, 122, 16, 154, 153, 153,
               153, 153, 153, 64, 64, 0, 0, 0, 0, 0, 0, 70, 192>>
  end

  test "Sub.i, infinity, -infinity, nan" do
    assert %Sub{i: [:infinity, :"-infinity", :nan]}
           |> Protox.Encode.encode()
           |> :binary.list_to_bin() ==
             <<122, 24, 0, 0, 0, 0, 0, 0, 0xF0, 0x7F, 0, 0, 0, 0, 0, 0, 0xF0, 0xFF, 0, 0, 0, 0, 0,
               1, 241, 255>>
  end

  test "Sub.h" do
    assert %Sub{h: [-1, -2]} |> Protox.Encode.encode() |> :binary.list_to_bin() ==
             <<114, 8, 255, 255, 255, 255, 254, 255, 255, 255>>
  end

  test "Sub.j, unpacked in definition" do
    assert %Sub{j: [1, 2, 3]} |> Protox.Encode.encode() |> :binary.list_to_bin() ==
             <<128, 1, 1, 128, 1, 2, 128, 1, 3>>
  end

  test "Sub.k; Sub.l" do
    assert %Sub{k: 23, l: -99} |> Protox.Encode.encode() |> :binary.list_to_bin() ==
             <<141, 1, 23, 0, 0, 0, 145, 1, 157, 255, 255, 255, 255, 255, 255, 255>>
  end

  test "Sub.m, empty" do
    assert %Sub{m: <<>>} |> Protox.Encode.encode() |> :binary.list_to_bin() == <<>>
  end

  test "Sub.m" do
    assert %Sub{m: <<1, 2, 3>>} |> Protox.Encode.encode() |> :binary.list_to_bin() ==
             <<154, 1, 3, 1, 2, 3>>
  end

  test "Sub.n" do
    assert %Sub{n: [true, false, false, true]} |> Protox.Encode.encode() |> :binary.list_to_bin() ==
             <<162, 1, 4, 1, 0, 0, 1>>
  end

  test "Sub.n (all true)" do
    assert %Sub{n: [true, true, true, true]} |> Protox.Encode.encode() |> :binary.list_to_bin() ==
             <<162, 1, 4, 1, 1, 1, 1>>
  end

  test "Sub.n (all false)" do
    assert %Sub{n: [false, false, false, false]}
           |> Protox.Encode.encode()
           |> :binary.list_to_bin() ==
             <<162, 1, 4, 0, 0, 0, 0>>
  end

  test "Sub.o " do
    assert %Sub{o: [:FOO, :BAR, :FOO]} |> Protox.Encode.encode() |> :binary.list_to_bin() ==
             <<170, 1, 3, 0, 1, 0>>
  end

  test "Sub.o (unknown entry) " do
    assert %Sub{o: [:FOO, :BAR, :FOO, 2]} |> Protox.Encode.encode() |> :binary.list_to_bin() ==
             <<170, 1, 4, 0, 1, 0, 2>>
  end

  test "Sub.p (unpacked in definition) " do
    assert %Sub{p: [true, false, true, false]} |> Protox.Encode.encode() |> :binary.list_to_bin() ==
             <<176, 1, 1, 176, 1, 0, 176, 1, 1, 176, 1, 0>>
  end

  test "Sub.q (unpacked in definition) " do
    assert %Sub{q: [:FOO, :BAR, :BAR, :FOO]} |> Protox.Encode.encode() |> :binary.list_to_bin() ==
             <<184, 1, 0, 184, 1, 1, 184, 1, 1, 184, 1, 0>>
  end

  test "Sub.q (unpacked in definition, with unknown values) " do
    assert %Sub{q: [:FOO, :BAR, 2, :FOO]} |> Protox.Encode.encode() |> :binary.list_to_bin() ==
             <<184, 1, 0, 184, 1, 1, 184, 1, 2, 184, 1, 0>>
  end

  test "Sub.r, negative constant" do
    assert %Sub{r: :NEG} |> Protox.Encode.encode() |> :binary.list_to_bin() ==
             <<192, 1, 255, 255, 255, 255, 255, 255, 255, 255, 255, 1>>
  end

  test "Sub.z" do
    assert %Sub{z: -20} |> Protox.Encode.encode() |> :binary.list_to_bin() == <<136, 241, 4, 39>>
  end

  test "Sub, unknown fields (double)" do
    assert %Sub{
             a: 42,
             b: "",
             z: -42,
             __uf__: [{3, 1, <<246, 40, 92, 143, 194, 53, 69, 64>>}]
           }
           |> Protox.Encode.encode()
           |> :binary.list_to_bin() ==
             <<8, 42, 136, 241, 4, 83, 25, 246, 40, 92, 143, 194, 53, 69, 64>>
  end

  test "Sub, unknown tag (embedded message)" do
    assert %Sub{a: 42, b: "", z: -42, __uf__: [{4, 2, <<>>}]}
           |> Protox.Encode.encode()
           |> :binary.list_to_bin() == <<8, 42, 136, 241, 4, 83, 34, 0>>
  end

  test "Sub, unknown tag (string)" do
    assert %Sub{
             a: 42,
             b: "",
             z: -42,
             __uf__: [{5, 2, <<121, 97, 121, 101>>}]
           }
           |> Protox.Encode.encode()
           |> :binary.list_to_bin() == <<8, 42, 136, 241, 4, 83, 42, 4, 121, 97, 121, 101>>
  end

  test "Sub, unknown tag (bytes)" do
    bytes = Stream.repeatedly(fn -> <<0>> end) |> Enum.take(128) |> Enum.join()

    assert %Sub{a: 3342, b: "", z: -10, __uf__: [{10, 2, bytes}]}
           |> Protox.Encode.encode()
           |> :binary.list_to_bin() == <<8, 142, 26, 136, 241, 4, 19, 82, 128, 1, bytes::binary>>
  end

  test "Sub, unknown tag (varint + bytes)" do
    assert %Sub{
             a: 3342,
             b: "",
             z: -10,
             __uf__: [
               {11, 0, <<154, 5>>},
               {10, 2, <<104, 101, 121, 33>>}
             ]
           }
           |> Protox.Encode.encode()
           |> :binary.list_to_bin() ==
             <<8, 142, 26, 136, 241, 4, 19, 88, 154, 5, 82, 4, 104, 101, 121, 33>>
  end

  test "Sub, unknown tag (float + varint + bytes)" do
    assert %Sub{
             a: 3342,
             b: "",
             z: -10,
             __uf__: [
               {12, 5, <<236, 81, 5, 66>>},
               {11, 0, <<154, 5>>},
               {10, 2, <<104, 101, 121, 33>>}
             ]
           }
           |> Protox.Encode.encode()
           |> :binary.list_to_bin() ==
             <<8, 142, 26, 136, 241, 4, 19, 101, 236, 81, 5, 66, 88, 154, 5, 82, 4, 104, 101, 121,
               33>>
  end

  test "Msg.msg_d, :FOO" do
    assert %Msg{msg_d: :FOO} |> Protox.Encode.encode() |> :binary.list_to_bin() == <<>>
  end

  test "Msg.msg_d, :BAR" do
    assert %Msg{msg_d: :BAR} |> Protox.Encode.encode() |> :binary.list_to_bin() == <<8, 1>>
  end

  test "Msg.msg_d, :BAZ" do
    assert %Msg{msg_d: :BAZ} |> Protox.Encode.encode() |> :binary.list_to_bin() == <<8, 1>>
  end

  test "Msg.msg_d, unknown value" do
    assert %Msg{msg_d: 99} |> Protox.Encode.encode() |> :binary.list_to_bin() == <<8, 99>>
  end

  test "Msg.msg_e, false" do
    assert %Msg{msg_e: false} |> Protox.Encode.encode() |> :binary.list_to_bin() == <<>>
  end

  test "Msg.msg_e, true" do
    assert %Msg{msg_e: true} |> Protox.Encode.encode() |> :binary.list_to_bin() == <<16, 1>>
  end

  test "Msg.msg_f, empty" do
    assert %Msg{msg_f: %Sub{}} |> Protox.Encode.encode() |> :binary.list_to_bin() == <<26, 0>>
  end

  test "Msg.msg_f.a" do
    assert %Msg{msg_f: %Sub{a: 150}} |> Protox.Encode.encode() |> :binary.list_to_bin() ==
             <<26, 3, 8, 150, 1>>
  end

  test "Msg.msg_g, empty" do
    assert %Msg{msg_g: []} |> Protox.Encode.encode() |> :binary.list_to_bin() == <<>>
  end

  test "Msg.msg_g (negative)" do
    assert %Msg{msg_g: [1, 2, -3]} |> Protox.Encode.encode() |> :binary.list_to_bin() ==
             <<34, 7, 1, 2, 253, 255, 255, 255, 15>>
  end

  test "Msg.msg_g" do
    assert %Msg{msg_g: [1, 2, 3]} |> Protox.Encode.encode() |> :binary.list_to_bin() ==
             <<34, 3, 1, 2, 3>>
  end

  test "Msg.msg_h, empty" do
    assert %Msg{msg_h: 0.0} |> Protox.Encode.encode() |> :binary.list_to_bin() == <<>>
  end

  test "Msg.msg_h" do
    assert %Msg{msg_h: -43.2} |> Protox.Encode.encode() |> :binary.list_to_bin() ==
             <<41, 154, 153, 153, 153, 153, 153, 69, 192>>
  end

  test "Msg.msg_i" do
    assert %Msg{msg_i: [2.3, -4.2]} |> Protox.Encode.encode() |> :binary.list_to_bin() ==
             <<50, 8, 51, 51, 19, 64, 102, 102, 134, 192>>
  end

  test "Msg.msg_i, infinity, -infinity, nan" do
    assert %Msg{msg_i: [:infinity, :"-infinity", :nan]}
           |> Protox.Encode.encode()
           |> :binary.list_to_bin() ==
             <<50, 12, 0, 0, 0x80, 0x7F, 0, 0, 0x80, 0xFF, 0, 1, 129, 255>>
  end

  test "Msg.msg_i, nan" do
    bytes = <<50, 12, 0x01, 0, 0x80, 0x7F, 0, 0, 0xC0, 0xFF, 0xFF, 0xFF, 0xFF, 0x7F>>

    assert Msg.decode!(bytes) == %Msg{
             msg_d: :FOO,
             msg_e: false,
             msg_f: nil,
             msg_g: [],
             msg_h: 0.0,
             msg_i: [:nan, :nan, :nan],
             msg_j: [],
             msg_k: %{}
           }
  end

  test "Msg.msg_j" do
    assert %Msg{msg_j: [%Sub{a: 42}, %Sub{b: "foo"}]}
           |> Protox.Encode.encode()
           |> :binary.list_to_bin() ==
             <<58, 2, 8, 42, 58, 5, 18, 3, 102, 111, 111>>
  end

  test "Msg.msg_k" do
    assert %Msg{msg_k: %{1 => "foo", 2 => "bar"}}
           |> Protox.Encode.encode()
           |> :binary.list_to_bin() ==
             <<66, 7, 8, 1, 18, 3, 102, 111, 111, 66, 7, 8, 2, 18, 3, 98, 97, 114>>
  end

  test "Msg.msg_l" do
    assert %Msg{msg_l: %{"bar" => 1.0, "foo" => 43.2}}
           |> Protox.Encode.encode()
           |> :binary.list_to_bin() ==
             <<74, 14, 10, 3, 98, 97, 114, 17, 0, 0, 0, 0, 0, 0, 240, 63, 74, 14, 10, 3, 102, 111,
               111, 17, 154, 153, 153, 153, 153, 153, 69, 64>>
  end

  test "Msg.msg_m, string" do
    assert %Msg{msg_m: {:msg_n, "bar"}} |> Protox.Encode.encode() |> :binary.list_to_bin() ==
             <<82, 3, 98, 97, 114>>
  end

  test "Msg.msg_m, Sub" do
    assert %Msg{msg_m: {:msg_o, %Sub{a: 42}}} |> Protox.Encode.encode() |> :binary.list_to_bin() ==
             <<90, 2, 8, 42>>
  end

  test "Msg.msg_p" do
    assert %Msg{msg_p: %{1 => :BAR}} |> Protox.Encode.encode() |> :binary.list_to_bin() ==
             <<98, 4, 8, 1, 16, 1>>
  end

  test "Msg.msg_q" do
    assert %Msg{msg_q: nil} |> Protox.Encode.encode() |> :binary.list_to_bin() == <<>>
  end

  test "Msg.msg_oneof_double" do
    assert %Msg{msg_oneof_field: {:msg_oneof_double, 0}}
           |> Protox.Encode.encode()
           |> :binary.list_to_bin() ==
             <<177, 7, 0, 0, 0, 0, 0, 0, 0, 0>>
  end

  test "Empty" do
    assert %Empty{} |> Protox.Encode.encode() |> :binary.list_to_bin() == <<>>
  end

  test "Upper.empty" do
    assert %Upper{empty: %Empty{}} |> Protox.Encode.encode() |> :binary.list_to_bin() == <<26, 0>>
  end

  test "Protobuf2.s, default" do
    assert %Protobuf2{s: :TWO} |> Protox.Encode.encode() |> :binary.list_to_bin() == <<>>
  end

  test "Protobuf2.s" do
    assert %Protobuf2{s: :ONE} |> Protox.Encode.encode() |> :binary.list_to_bin() == <<200, 1, 1>>
  end

  test "Protobuf2.t, default is nil" do
    assert %Protobuf2{t: nil} |> Protox.Encode.encode() |> :binary.list_to_bin() == <<>>
  end
end
