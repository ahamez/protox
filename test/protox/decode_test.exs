defmodule Protox.DecodeTest do
  use ExUnit.Case


  test "Sub.a" do
    bytes = <<8, 150, 1>>
    assert Sub.decode!(bytes) ==\
           %Sub{a: 150, b: ""}
  end


  test "Sub.a, negative 64 bits" do
    bytes = <<8, 234, 254, 255, 255, 255, 255, 255, 255, 255, 1>>
    assert Sub.decode!(bytes) ==\
           %Sub{a: -150, b: ""}
  end


  test "Sub.a, negative 32 bits" do
    bytes = <<8, 234, 254, 255, 255, 15>>
    assert Sub.decode!(bytes) ==\
           %Sub{a: -150, b: ""}
  end


  test "Sub.b" do
    bytes = <<18, 7, 116, 101, 115, 116, 105, 110, 103>>
    assert Sub.decode!(bytes) ==\
           %Sub{a: 0, b: "testing"}
  end


  test "Sub.b, empty" do
    bytes = <<18, 0>>
    assert Sub.decode!(bytes) ==\
           %Sub{a: 0, b: ""}
  end


  test "Sub.a; Sub.b" do
    bytes = <<8, 150, 1, 18, 7, 116, 101, 115, 116, 105, 110, 103>>
    assert Sub.decode!(bytes) ==\
           %Sub{a: 150, b: "testing"}
  end


  test "Sub.a; Sub.b; Sub.z" do
    bytes = <<8, 150, 1, 18, 7, 116, 101, 115, 116, 105, 110, 103, 136, 241, 4, 157, 156, 1>>
    assert Sub.decode!(bytes) ==\
           %Sub{a: 150, b: "testing", z: -9999}
  end


  test "Sub.b; Sub.a" do
    bytes = <<18, 7, 116, 101, 115, 116, 105, 110, 103, 8, 150, 1>>
    assert Sub.decode!(bytes) ==\
           %Sub{a: 150, b: "testing"}
  end


  test "Sub, unknown tag (double)" do
    bytes = <<8, 42, 25, 246, 40, 92, 143, 194, 53, 69, 64, 136, 241, 4, 83>>
    assert Sub.decode!(bytes) ==\
           %Sub{a: 42, b: "", z: -42, __uf__: [{3, 1, <<246, 40, 92, 143, 194, 53, 69, 64>>}]}
  end


  test "Sub, unknown tag (embedded message)" do
    bytes = <<8, 42, 34, 0, 136, 241, 4, 83>>
    assert Sub.decode!(bytes) ==\
           %Sub{a: 42, b: "", z: -42, __uf__: [{4, 2, <<>>}]}
  end


  test "Sub, unknown tag (string)" do
    bytes = <<8, 42, 42, 4, 121, 97, 121, 101, 136, 241, 4, 83>>
    assert Sub.decode!(bytes) ==\
           %Sub{a: 42, b: "", z: -42, __uf__: [{5, 2, <<121, 97, 121, 101>>}]}
  end


  test "Sub, unknown tag (bytes)" do
    bytes = <<8, 142, 26, 82, 4, 104, 101, 121, 33, 136, 241, 4, 19>>
    assert Sub.decode!(bytes) ==\
           %Sub{a: 3342, b: "", z: -10, __uf__: [{10, 2, <<104, 101, 121, 33>>}]}
  end


  test "Sub, unknown tag (varint)" do
    bytes = <<8, 142, 26, 82, 4, 104, 101, 121, 33, 88, 154, 5, 136, 241, 4, 19>>
    assert Sub.decode!(bytes) ==\
           %Sub{a: 3342, b: "", z: -10, __uf__: [{11, 0, <<154, 5>>}, {10, 2, <<104, 101, 121, 33>>}]}
  end


  test "Sub, unknown tag (float)" do
    bytes = <<8, 142, 26, 82, 4, 104, 101, 121, 33, 88, 154, 5, 101, 236, 81, 5, 66, 136,
              241, 4, 19>>
    assert Sub.decode!(bytes) ==\
           %Sub{a: 3342, b: "", z: -10, __uf__: [{12, 5, <<236, 81, 5, 66>>}, {11, 0, <<154, 5>>}, {10, 2, <<104, 101, 121, 33>>}]}
  end


  test "Sub.c" do
    bytes = <<48, 212, 253, 255, 255, 255, 255, 255, 255, 255, 1>>
    assert Sub.decode!(bytes) ==\
           %Sub{a: 0, b: "", c: -300}
  end


  test "Sub.d; Sub.e" do
    bytes = <<56, 133, 7, 64, 177, 3>>
    assert Sub.decode!(bytes) ==\
           %Sub{a: 0, b: "", c: 0, d: 901, e: 433}
  end


  test "Sub.f" do
    bytes = <<72, 213, 20>>
    assert Sub.decode!(bytes) ==\
           %Sub{a: 0, b: "", c: 0, d: 0, e: 0, f: -1323}
  end


  test "Sub.g" do
    bytes = <<106, 16, 1, 0, 0, 0, 0, 0, 0, 0, 254, 255,
              255, 255, 255, 255, 255, 255>>
    assert Sub.decode!(bytes) ==\
           %Sub{a: 0, b: "", c: 0, d: 0, e: 0, f: 0, g: [1,-2], h: [], i: []}
  end


  test "Sub.g, not contiguous, should be concatenated" do
    bytes = <<106, 8, 1, 0, 0, 0, 0, 0, 0, 0, 8, 150, 1, 106, 8, 254, 255,
              255, 255, 255, 255, 255, 255>>
    assert Sub.decode!(bytes) ==\
           %Sub{a: 150, c: 0, b: "", d: 0, e: 0, f: 0, g: [1,-2], h: [], i: []}
  end


  test "Sub.g; Sub.h; Sub.i" do
    bytes = <<106, 8, 0, 0, 0, 0, 0, 0, 0, 0, 114, 4, 255, 255, 255, 255, 122, 16, 154, 153,
              153, 153, 153, 153, 64, 64, 0, 0, 0, 0, 0, 0, 70, 192>>
    assert Sub.decode!(bytes) ==\
           %Sub{a: 0, b: "", c: 0, d: 0, e: 0, f: 0, g: [0], h: [-1], i: [33.2, -44.0]}
  end


  test "Sub.i, infinity" do
    bytes = <<122, 8, 0, 0, 0, 0, 0, 0, 0xF0, 0x7F>>
    assert Sub.decode!(bytes) ==\
           %Sub{i: [:infinity]}
  end


  test "Sub.i, -infinity" do
    bytes = <<122, 8, 0, 0, 0, 0, 0, 0, 0xF0, 0xFF>>
    assert Sub.decode!(bytes) ==\
           %Sub{i: [:'-infinity']}
  end


  test "Sub.i, nan" do
    bytes = <<122, 24, 0x01, 0, 0, 0, 0, 0, 0xF0, 0x7F, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
              0, 0, 0, 0, 0, 0, 0xF8, 0xFF>>
    assert Sub.decode!(bytes) ==\
           %Sub{i: [:nan, :nan, :nan]}
  end


  test "Sub.h" do
    bytes = <<114, 8, 255, 255, 255, 255, 254, 255, 255, 255>>
    assert Sub.decode!(bytes) ==\
           %Sub{a: 0, b: "", c: 0, d: 0, e: 0, f: 0, g: [], h: [-1,-2], i: []}
  end


  test "Sub.j, unpacked in definition" do
    bytes = <<128, 1, 1, 128, 1, 2, 128, 1, 3>>
    assert Sub.decode!(bytes) ==\
           %Sub{j: [1, 2, 3]}
  end


  test "Sub.n" do
    bytes = <<162, 1, 4, 1, 0, 0, 1>>
    assert Sub.decode!(bytes) ==\
           %Sub{a: 0, b: "", c: 0, d: 0, e: 0, f: 0, g: [], h: [], i: [],
                n: [true, false, false, true]}
  end


  test "Sub.n (all false)" do
    bytes = <<162, 1, 4, 0, 0, 0, 0>>
    assert Sub.decode!(bytes) ==\
           %Sub{a: 0, b: "", c: 0, d: 0, e: 0, f: 0, g: [], h: [], i: [],
                n: [false, false, false, false]}
  end


  test "Sub.o " do
    bytes = <<170, 1, 3, 0, 1, 0>>
    assert Sub.decode!(bytes) ==\
           %Sub{a: 0, b: "", c: 0, d: 0, e: 0, f: 0, g: [], h: [], i: [],
                n: [], o: [:FOO, :BAR, :FOO]}
  end


  test "Sub.o (unknown entry) " do
    bytes = <<170, 1, 4, 0, 1, 0, 2>>
    assert Sub.decode!(bytes) ==\
           %Sub{a: 0, b: "", c: 0, d: 0, e: 0, f: 0, g: [], h: [], i: [],
                n: [], o: [:FOO, :BAR, :FOO, 2]}
  end


  test "Sub.p" do
    bytes = <<176, 1, 1, 176, 1, 0, 176, 1, 1, 176, 1, 0>>
    assert Sub.decode!(bytes) ==\
           %Sub{a: 0, b: "", c: 0, d: 0, e: 0, f: 0, g: [], h: [], i: [],
                n: [], o: [], p: [true, false, true, false]}
  end


  test "Sub.p, not contiguous, should be concatenated" do
    bytes = <<176, 1, 1, 176, 1, 0, 8, 150, 1, 176, 1, 1, 176, 1, 0>>
    assert Sub.decode!(bytes) ==\
           %Sub{a: 150, c: 0, b: "", d: 0, e: 0, f: 0, g: [], h: [], i: [],
                n: [], o: [], p: [true, false, true, false]}
  end


  test "Sub.q (unpacked in definition) " do
    bytes = <<184, 1, 0, 184, 1, 1, 184, 1, 1, 184, 1, 0>>
    assert Sub.decode!(bytes) ==\
           %Sub{a: 0, b: "", c: 0, d: 0, e: 0, f: 0, g: [], h: [], i: [],
                n: [], o: [], p: [], q: [:FOO, :BAR, :BAR, :FOO]}
  end


  test "Sub.q (unpacked in definition, with unknown values) " do
    bytes = <<184, 1, 0, 184, 1, 1, 184, 1, 2, 184, 1, 0>>
    assert Sub.decode!(bytes) ==\
           %Sub{a: 0, b: "", c: 0, d: 0, e: 0, f: 0, g: [], h: [], i: [],
                n: [], o: [], p: [], q: [:FOO, :BAR, 2, :FOO]}
  end


  test "Sub.r, negative constant" do
    bytes = <<192, 1, 255, 255, 255, 255, 255, 255, 255, 255, 255, 1>>
    assert Sub.decode!(bytes) ==\
           %Sub{r: :NEG}
  end


  test "Sub.u" do
    bytes = <<218, 1, 6, 0, 1, 2, 3, 144, 78>>
    assert Sub.decode!(bytes) ==\
           %Sub{a: 0, b: "", c: 0, d: 0, e: 0, f: 0, g: [], h: [], i: [], u: [0, 1, 2, 3, 10_000]}
  end


  test "Sub.w" do
    bytes = <<226, 1, 7, 0, 1, 4, 5, 160, 156, 1>>
    assert Sub.decode!(bytes) ==\
           %Sub{a: 0, b: "", c: 0, d: 0, e: 0, f: 0, g: [], h: [], i: [], w: [0, -1, 2, -3, 10_000]}
  end


  test "Sub.x" do
    bytes = <<234, 1, 24, 0, 255, 255, 255, 255, 255, 255, 255, 255, 255, 1, 2, 253, 255,
              255, 255, 255, 255, 255, 255, 255, 1, 144, 78>>
    assert Sub.decode!(bytes) ==\
           %Sub{a: 0, b: "", c: 0, d: 0, e: 0, f: 0, g: [], h: [], i: [], x: [0, -1, 2, -3, 10_000]}
  end


  test "Sub.y" do
    bytes = <<242, 1, 6, 0, 1, 2, 3, 144, 78>>
    assert Sub.decode!(bytes) ==\
           %Sub{a: 0, b: "", c: 0, d: 0, e: 0, f: 0, g: [], h: [], i: [], y: [0, 1, 2, 3, 10_000]}
  end


  test "Msg.a" do
    bytes = <<218, 1, 7, 0, 2, 3, 6, 159, 156, 1>>
    assert Msg.decode!(bytes) ==\
           %Msg{a: [0, 1, -2, 3, -10_000]}
  end


  test "Msg.b" do
    bytes = <<226, 1, 20, 0, 0, 0, 0, 1, 0, 0, 0, 254, 255, 255, 255, 3, 0, 0, 0, 240, 216,
              255, 255>>
    assert Msg.decode!(bytes) ==\
           %Msg{b: [0, 1, -2, 3, -10_000]}
  end


  test "Msg.c" do
    bytes = <<234, 1, 40, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 254, 255, 255,
              255, 255, 255, 255, 255, 3, 0, 0, 0, 0, 0, 0, 0, 240, 216, 255, 255, 255, 255,
              255, 255>>
    assert Msg.decode!(bytes) ==\
           %Msg{c: [0, 1, -2, 3, -10_000]}
  end


  test "Msg.Sub.a" do
    bytes = <<26, 3, 8, 150, 1>>
    assert Msg.decode!(bytes) ==\
           %Msg{d: :FOO, e: false, f: %Sub{a: 150, b: ""}, g: [], h: 0.0, i: [], j: [],
               k: %{}}
  end


  test "Msg.Sub.a; Msg.Sub.b" do
    bytes = <<26, 12, 8, 150, 1, 18, 7, 116, 101, 115, 116, 105, 110, 103>>
    assert Msg.decode!(bytes) ==\
           %Msg{d: :FOO, e: false, f: %Sub{a: 150, b: "testing"}, g: [], h: 0.0, i: [],
               j: [], k: %{}}
  end


  test "Msg.g" do
    bytes = <<34, 6, 3, 142, 2, 158, 167, 5>>
    assert Msg.decode!(bytes) ==\
           %Msg{d: :FOO, e: false, f: nil, g: [3, 270, 86_942], h: 0.0, i: [], j: [], k: %{}}
  end


  test "Msg.g (unpacked)" do
    bytes = <<32, 1, 32, 2, 32, 3>>
    assert Msg.decode!(bytes) ==\
           %Msg{d: :FOO, e: false, f: nil, g: [1, 2, 3], h: 0.0, i: [], j: [], k: %{}}
  end


  test "Msg.Sub.a; Msg.Sub.b; Msg.g" do
    bytes = <<26, 12, 8, 150, 1, 18, 7, 116, 101, 115, 116, 105, 110, 103, 34, 6, 3, 142,
              2, 158, 167, 5>>
    assert Msg.decode!(bytes) ==\
           %Msg{d: :FOO, e: false, f: %Sub{a: 150, b: "testing"}, g: [3, 270, 86_942],
                h: 0.0, i: [], j: [], k: %{}}
  end


  test "Msg.e" do
    bytes = <<16, 1>>
    assert Msg.decode!(bytes) ==\
           %Msg{d: :FOO, e: true, f: nil, g: [], h: 0.0, i: [], j: [], k: %{}}
  end


  test "Msg.h" do
    bytes = <<41, 246, 40, 92, 143, 194, 181, 64, 192>>
    assert Msg.decode!(bytes) ==\
           %Msg{d: :FOO, e: false, f: nil, g: [], h: -33.42, i: [], j: [], k: %{}}
  end


  test "Msg.i" do
    bytes = <<50, 8, 0, 0, 128, 63, 0, 0, 0, 64>>
    assert Msg.decode!(bytes) ==\
           %Msg{d: :FOO, e: false, f: nil, g: [], h: 0.0, i: [1.0, 2.0], j: [], k: %{}}
  end


  test "Msg.i, infinity, -infinity" do
    bytes = <<50, 8, 0, 0, 0x80, 0x7F, 0, 0, 0x80, 0xFF>>
    assert Msg.decode!(bytes) ==\
           %Msg{d: :FOO, e: false, f: nil, g: [], h: 0.0, i: [:infinity, :'-infinity'], j: [], k: %{}}
  end


  test "Msg.i, nan" do
    bytes = <<50, 12, 0x01, 0, 0x80, 0x7F, 0, 0, 0xC0, 0xFF, 0xFF, 0xFF, 0xFF, 0x7F>>
    assert Msg.decode!(bytes) ==\
           %Msg{d: :FOO, e: false, f: nil, g: [], h: 0.0, i: [:nan, :nan, :nan], j: [], k: %{}}
  end


  test "Msg.d" do
    bytes = <<8, 1>>
    assert Msg.decode!(bytes) ==\
           %Msg{d: :BAR, e: false, f: nil, g: [], h: 0.0, i: [], j: [], k: %{}}
  end


  test "Msg.d, unknown enum entry" do
    bytes = <<8, 2>>
    assert Msg.decode!(bytes) ==\
           %Msg{d: 2, e: false, f: nil, g: [], h: 0.0, i: [], j: [], k: %{}}
  end


  test "Msg.j" do
    bytes = <<58, 3, 8, 146, 6, 58, 5, 18, 3, 102, 111, 111>>
    assert Msg.decode!(bytes) ==\
           %Msg{d: :FOO, e: false, f: nil, g: [], h: 0.0, i: [],
                j: [%Sub{a: 786}, %Sub{b: "foo"}], k: %{}}
  end


  test "Msg.k" do
    bytes = <<66, 7, 8, 2, 18, 3, 98, 97, 114, 66, 7, 8, 1, 18, 3, 102, 111, 111>>
    assert Msg.decode!(bytes) ==\
           %Msg{d: :FOO, e: false, f: nil, g: [], h: 0.0, i: [], j: [],
                k: %{1 => "foo", 2 => "bar"}}
  end


  test "Msg.k, with unknown data in map entry" do
    bytes = <<66, 7, 8, 2, 18, 3, 98, 97, 114, 66, 10, 8, 1, 18, 3, 102, 111, 111, 26, 1, 102>>
    assert Msg.decode!(bytes) ==\
           %Msg{d: :FOO, e: false, f: nil, g: [], h: 0.0, i: [], j: [],
                k: %{1 => "foo", 2 => "bar"}}
  end


  test "Msg.k (reversed)" do
    bytes = <<66, 7, 8, 1, 18, 3, 102, 111, 111, 66, 7, 8, 2, 18, 3, 98, 97, 114>>
    assert Msg.decode!(bytes) ==\
           %Msg{d: :FOO, e: false, f: nil, g: [], h: 0.0, i: [], j: [],
                k: %{1 => "foo", 2 => "bar"}}
  end


  test "Msg.k (reversed inside map entry)" do
    bytes = <<66, 7, 18, 3, 98, 97, 114, 8, 2, 66, 7, 8, 1, 18, 3, 102, 111, 111>>
    assert Msg.decode!(bytes) ==\
           %Msg{d: :FOO, e: false, f: nil, g: [], h: 0.0, i: [], j: [],
                k: %{1 => "foo", 2 => "bar"}}
  end


  test "Msg.l" do
    bytes = <<74, 14, 10, 3, 98, 97, 114, 17, 0, 0, 0, 0, 0, 0, 240, 63, 74, 14, 10, 3, 102,
              111, 111, 17, 154, 153, 153, 153, 153, 153, 69, 64>>
    assert Msg.decode!(bytes) ==\
           %Msg{d: :FOO, e: false, f: nil, g: [], h: 0.0, i: [], j: [],
                k: %{}, l: %{"bar" => 1.0, "foo" => 43.2}}
  end


  test "Msg.m, empty" do
    bytes = ""
    assert Msg.decode!(bytes) ==\
           %Msg{d: :FOO, e: false, f: nil, g: [], h: 0.0, i: [], j: [], k: %{}, l: %{}, m: nil}
  end


  test "Msg.m, string" do
    bytes = <<82, 3, 98, 97, 114>>
    assert Msg.decode!(bytes) ==\
           %Msg{d: :FOO, e: false, f: nil, g: [], h: 0.0, i: [], j: [],
                k: %{}, l: %{}, m: {:n, "bar"}}
  end


  test "Msg.m, Sub" do
    bytes = <<90, 2, 8, 42>>
    assert Msg.decode!(bytes) ==\
           %Msg{d: :FOO, e: false, f: nil, g: [], h: 0.0, i: [], j: [],
                k: %{}, l: %{}, m: {:o, %Sub{a: 42}}}
  end


  test "Msg.m, several fields on the wire, keep the last one" do
    bytes = <<90, 2, 8, 42, 82, 3, 98, 97, 114, 82, 3, 98, 97, 114>>
    assert Msg.decode!(bytes) ==\
           %Msg{d: :FOO, e: false, f: nil, g: [], h: 0.0, i: [], j: [],
                k: %{}, l: %{}, m: {:n, "bar"}}
  end


  test "Upper.msg.f" do
    bytes = <<10, 4, 26, 2, 8, 42>>
    assert Upper.decode!(bytes) ==\
           %Upper{msg: %Msg{d: :FOO, e: false, f: %Sub{a: 42}, g: [], h: 0.0, i: [], j: []}}
  end


  test "Upper.msg_map" do
    bytes = <<18, 9, 10, 3, 102, 111, 111, 18, 2, 8, 1, 18, 9, 10, 3, 98, 97, 122, 18, 2, 16, 1>>
    assert Upper.decode!(bytes) ==\
           %Upper{
              msg: nil,
              msg_map: %{
                "foo" => %Msg{d: :BAR, e: false, f: nil, g: [], h: 0.0, i: [], j: [],
                              k: %{}, l: %{}, m: nil},
                "baz" => %Msg{d: :FOO, e: true, f: nil, g: [], h: 0.0, i: [], j: [],
                              k: %{}, l: %{}, m: nil},
              }
            }
  end


  test "Upper.empty" do
    bytes = <<26, 0>>
    assert Upper.decode!(bytes) ==\
           %Upper{empty: %Empty{}}
  end


  test "Empty" do
    bytes = <<>>
    assert Empty.decode!(bytes) ==\
           %Empty{}
  end


  test "Dummy data" do
    assert {:error, _} = Empty.decode(<<1,2,3>>)
  end


  test "Required field" do
    assert {:error, %RuntimeError{message: "Missing required fields [:a]"}} = Required.decode(<<>>)
  end


  test "No name clash for __uf__" do
    assert NoNameClash.decode!(<<>>) ==\
           %NoNameClash{__uf__: 0}
  end

  test "Protobuf2.s, default" do
    bytes = <<>>
    assert Protobuf2.decode!(bytes) ==\
           %Protobuf2{s: :TWO}
  end


  test "Protobuf2.s" do
    bytes = <<200, 1, 2>>
    assert Protobuf2.decode!(bytes) ==\
           %Protobuf2{s: :TWO}
  end


  test "Protobuf2.t, default is nil" do
    bytes = <<>>
    assert Protobuf2.decode!(bytes) ==\
           %Protobuf2{t: nil}
  end

end
