defmodule Protox.DecodeTest do
  use ExUnit.Case

  Code.require_file("test/messages.exs")

  test "Sub.a" do
    bytes = <<8, 150, 1>>
    assert Sub.decode!(bytes) == %Sub{a: 150, b: ""}
  end

  test "Sub.a, repeated scalar, select last" do
    bytes = <<8, 150, 1, 8, 1, 8, 150, 1, 8, 2>>
    assert Sub.decode!(bytes) == %Sub{a: 2, b: ""}
  end

  test "Sub.a, negative 64 bits" do
    bytes = <<8, 234, 254, 255, 255, 255, 255, 255, 255, 255, 1>>
    assert Sub.decode!(bytes) == %Sub{a: -150, b: ""}
  end

  test "Sub.a, negative 32 bits" do
    bytes = <<8, 234, 254, 255, 255, 15>>
    assert Sub.decode!(bytes) == %Sub{a: -150, b: ""}
  end

  test "Sub.b" do
    bytes = <<18, 7, 116, 101, 115, 116, 105, 110, 103>>
    assert Sub.decode!(bytes) == %Sub{a: 0, b: "testing"}
  end

  test "Sub.b, empty" do
    bytes = <<18, 0>>
    assert Sub.decode!(bytes) == %Sub{a: 0, b: ""}
  end

  test "Sub.a; Sub.b" do
    bytes = <<8, 150, 1, 18, 7, 116, 101, 115, 116, 105, 110, 103>>
    assert Sub.decode!(bytes) == %Sub{a: 150, b: "testing"}
  end

  test "Sub.a; Sub.b; Sub.z" do
    bytes = <<8, 150, 1, 18, 7, 116, 101, 115, 116, 105, 110, 103, 136, 241, 4, 157, 156, 1>>
    assert Sub.decode!(bytes) == %Sub{a: 150, b: "testing", z: -9999}
  end

  test "Sub.b; Sub.a" do
    bytes = <<18, 7, 116, 101, 115, 116, 105, 110, 103, 8, 150, 1>>
    assert Sub.decode!(bytes) == %Sub{a: 150, b: "testing"}
  end

  test "Sub, unknown tag (double)" do
    bytes = <<8, 42, 25, 246, 40, 92, 143, 194, 53, 69, 64, 136, 241, 4, 83>>

    assert Sub.decode!(bytes) == %Sub{
             a: 42,
             b: "",
             z: -42,
             __uf__: [{3, 1, <<246, 40, 92, 143, 194, 53, 69, 64>>}]
           }
  end

  test "Sub, unknown tag (embedded message)" do
    bytes = <<8, 42, 34, 0, 136, 241, 4, 83>>
    assert Sub.decode!(bytes) == %Sub{a: 42, b: "", z: -42, __uf__: [{4, 2, <<>>}]}
  end

  test "Sub, unknown tag (string)" do
    bytes = <<8, 42, 42, 4, 121, 97, 121, 101, 136, 241, 4, 83>>

    assert Sub.decode!(bytes) == %Sub{
             a: 42,
             b: "",
             z: -42,
             __uf__: [{5, 2, <<121, 97, 121, 101>>}]
           }
  end

  test "Sub, unknown tag (bytes)" do
    bytes = <<8, 142, 26, 82, 4, 104, 101, 121, 33, 136, 241, 4, 19>>

    assert Sub.decode!(bytes) == %Sub{
             a: 3342,
             b: "",
             z: -10,
             __uf__: [{10, 2, <<104, 101, 121, 33>>}]
           }
  end

  test "Sub, unknown tag (varint)" do
    bytes = <<8, 142, 26, 82, 4, 104, 101, 121, 33, 88, 154, 5, 136, 241, 4, 19>>

    assert Sub.decode!(bytes) == %Sub{
             a: 3342,
             b: "",
             z: -10,
             __uf__: [{11, 0, <<154, 5>>}, {10, 2, <<104, 101, 121, 33>>}]
           }
  end

  test "Sub, unknown tag (float)" do
    bytes =
      <<8, 142, 26, 82, 4, 104, 101, 121, 33, 88, 154, 5, 101, 236, 81, 5, 66, 136, 241, 4, 19>>

    assert Sub.decode!(bytes) == %Sub{
             a: 3342,
             b: "",
             z: -10,
             __uf__: [
               {12, 5, <<236, 81, 5, 66>>},
               {11, 0, <<154, 5>>},
               {10, 2, <<104, 101, 121, 33>>}
             ]
           }
  end

  test "Sub.c" do
    bytes = <<48, 212, 253, 255, 255, 255, 255, 255, 255, 255, 1>>
    assert Sub.decode!(bytes) == %Sub{a: 0, b: "", c: -300}
  end

  test "Sub.d; Sub.e" do
    bytes = <<56, 133, 7, 64, 177, 3>>
    assert Sub.decode!(bytes) == %Sub{a: 0, b: "", c: 0, d: 901, e: 433}
  end

  test "Sub.d, overflow values > MAX UINT32" do
    #  <<128, 128, 128, 128, 32>> == 8589934592
    bytes = <<56, 128, 128, 128, 128, 32>>
    assert Sub.decode!(bytes) == %Sub{d: 0}
  end

  test "Sub.f" do
    bytes = <<72, 213, 20>>
    assert Sub.decode!(bytes) == %Sub{a: 0, b: "", c: 0, d: 0, e: 0, f: -1323}
  end

  test "Sub.g" do
    bytes = <<106, 16, 1, 0, 0, 0, 0, 0, 0, 0, 254, 255, 255, 255, 255, 255, 255, 255>>

    assert Sub.decode!(bytes) == %Sub{
             a: 0,
             b: "",
             c: 0,
             d: 0,
             e: 0,
             f: 0,
             g: [1, 18_446_744_073_709_551_614],
             h: [],
             i: []
           }
  end

  test "Sub.g, not contiguous, should be concatenated" do
    bytes =
      <<106, 8, 1, 0, 0, 0, 0, 0, 0, 0, 8, 150, 1, 106, 8, 254, 255, 255, 255, 255, 255, 255,
        255>>

    assert Sub.decode!(bytes) == %Sub{
             a: 150,
             c: 0,
             b: "",
             d: 0,
             e: 0,
             f: 0,
             g: [1, 18_446_744_073_709_551_614],
             h: [],
             i: []
           }
  end

  test "Sub.g; Sub.h; Sub.i" do
    bytes =
      <<106, 8, 0, 0, 0, 0, 0, 0, 0, 0, 114, 4, 255, 255, 255, 255, 122, 16, 154, 153, 153, 153,
        153, 153, 64, 64, 0, 0, 0, 0, 0, 0, 70, 192>>

    assert Sub.decode!(bytes) == %Sub{
             a: 0,
             b: "",
             c: 0,
             d: 0,
             e: 0,
             f: 0,
             g: [0],
             h: [-1],
             i: [33.2, -44.0]
           }
  end

  test "Sub.i, infinity" do
    bytes = <<122, 8, 0, 0, 0, 0, 0, 0, 0xF0, 0x7F>>
    assert Sub.decode!(bytes) == %Sub{i: [:infinity]}
  end

  test "Sub.i, -infinity" do
    bytes = <<122, 8, 0, 0, 0, 0, 0, 0, 0xF0, 0xFF>>
    assert Sub.decode!(bytes) == %Sub{i: [:"-infinity"]}
  end

  test "Sub.i, nan" do
    bytes =
      <<122, 24, 0x01, 0, 0, 0, 0, 0, 0xF0, 0x7F, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
        0, 0, 0, 0, 0, 0, 0xF8, 0xFF>>

    assert Sub.decode!(bytes) == %Sub{i: [:nan, :nan, :nan]}
  end

  test "Sub.h" do
    bytes = <<114, 8, 255, 255, 255, 255, 254, 255, 255, 255>>

    assert Sub.decode!(bytes) == %Sub{
             a: 0,
             b: "",
             c: 0,
             d: 0,
             e: 0,
             f: 0,
             g: [],
             h: [-1, -2],
             i: []
           }
  end

  test "Sub.j, unpacked in definition" do
    bytes = <<128, 1, 1, 128, 1, 2, 128, 1, 3>>
    assert Sub.decode!(bytes) == %Sub{j: [1, 2, 3]}
  end

  test "Sub.n" do
    bytes = <<162, 1, 4, 1, 0, 0, 1>>

    assert Sub.decode!(bytes) == %Sub{
             a: 0,
             b: "",
             c: 0,
             d: 0,
             e: 0,
             f: 0,
             g: [],
             h: [],
             i: [],
             n: [true, false, false, true]
           }
  end

  test "Sub.n (all false)" do
    bytes = <<162, 1, 4, 0, 0, 0, 0>>

    assert Sub.decode!(bytes) == %Sub{
             a: 0,
             b: "",
             c: 0,
             d: 0,
             e: 0,
             f: 0,
             g: [],
             h: [],
             i: [],
             n: [false, false, false, false]
           }
  end

  test "Sub.o " do
    bytes = <<170, 1, 3, 0, 1, 0>>

    assert Sub.decode!(bytes) == %Sub{
             a: 0,
             b: "",
             c: 0,
             d: 0,
             e: 0,
             f: 0,
             g: [],
             h: [],
             i: [],
             n: [],
             o: [:FOO, :BAR, :FOO]
           }
  end

  test "Sub.o (unknown entry) " do
    bytes = <<170, 1, 4, 0, 1, 0, 2>>

    assert Sub.decode!(bytes) == %Sub{
             a: 0,
             b: "",
             c: 0,
             d: 0,
             e: 0,
             f: 0,
             g: [],
             h: [],
             i: [],
             n: [],
             o: [:FOO, :BAR, :FOO, 2]
           }
  end

  test "Sub.p" do
    bytes = <<176, 1, 1, 176, 1, 0, 176, 1, 1, 176, 1, 0>>

    assert Sub.decode!(bytes) == %Sub{
             a: 0,
             b: "",
             c: 0,
             d: 0,
             e: 0,
             f: 0,
             g: [],
             h: [],
             i: [],
             n: [],
             o: [],
             p: [true, false, true, false]
           }
  end

  test "Sub.p, not contiguous, should be concatenated" do
    bytes = <<176, 1, 1, 176, 1, 0, 8, 150, 1, 176, 1, 1, 176, 1, 0>>

    assert Sub.decode!(bytes) == %Sub{
             a: 150,
             c: 0,
             b: "",
             d: 0,
             e: 0,
             f: 0,
             g: [],
             h: [],
             i: [],
             n: [],
             o: [],
             p: [true, false, true, false]
           }
  end

  test "Sub.p, packed and unpacked, should be concatenated" do
    packed = <<178, 1, 2, 1, 0>>
    unpacked = <<176, 1, 1, 176, 1, 0>>
    merge_1 = packed <> unpacked
    merge_2 = unpacked <> packed

    msg = %Sub{p: [true, false, true, false]}

    assert Sub.decode!(packed) == Sub.decode!(unpacked)
    assert Sub.decode!(merge_1) == msg
    assert Sub.decode!(merge_2) == msg
  end

  test "Sub.q (unpacked in definition) " do
    bytes = <<184, 1, 0, 184, 1, 1, 184, 1, 1, 184, 1, 0>>

    assert Sub.decode!(bytes) == %Sub{
             a: 0,
             b: "",
             c: 0,
             d: 0,
             e: 0,
             f: 0,
             g: [],
             h: [],
             i: [],
             n: [],
             o: [],
             p: [],
             q: [:FOO, :BAR, :BAR, :FOO]
           }
  end

  test "Sub.q (unpacked in definition, with unknown values) " do
    bytes = <<184, 1, 0, 184, 1, 1, 184, 1, 2, 184, 1, 0>>

    assert Sub.decode!(bytes) == %Sub{
             a: 0,
             b: "",
             c: 0,
             d: 0,
             e: 0,
             f: 0,
             g: [],
             h: [],
             i: [],
             n: [],
             o: [],
             p: [],
             q: [:FOO, :BAR, 2, :FOO]
           }
  end

  test "Sub.r, negative constant" do
    bytes = <<192, 1, 255, 255, 255, 255, 255, 255, 255, 255, 255, 1>>
    assert Sub.decode!(bytes) == %Sub{r: :NEG}
  end

  test "Sub.u" do
    bytes = <<218, 1, 6, 0, 1, 2, 3, 144, 78>>

    assert Sub.decode!(bytes) == %Sub{
             a: 0,
             b: "",
             c: 0,
             d: 0,
             e: 0,
             f: 0,
             g: [],
             h: [],
             i: [],
             u: [0, 1, 2, 3, 10_000]
           }
  end

  test "Sub.w" do
    bytes = <<226, 1, 7, 0, 1, 4, 5, 160, 156, 1>>

    assert Sub.decode!(bytes) == %Sub{
             a: 0,
             b: "",
             c: 0,
             d: 0,
             e: 0,
             f: 0,
             g: [],
             h: [],
             i: [],
             w: [0, -1, 2, -3, 10_000]
           }
  end

  test "Sub.x" do
    bytes =
      <<234, 1, 24, 0, 255, 255, 255, 255, 255, 255, 255, 255, 255, 1, 2, 253, 255, 255, 255, 255,
        255, 255, 255, 255, 1, 144, 78>>

    assert Sub.decode!(bytes) == %Sub{
             a: 0,
             b: "",
             c: 0,
             d: 0,
             e: 0,
             f: 0,
             g: [],
             h: [],
             i: [],
             x: [0, -1, 2, -3, 10_000]
           }
  end

  test "Sub.y" do
    bytes = <<242, 1, 6, 0, 1, 2, 3, 144, 78>>

    assert Sub.decode!(bytes) == %Sub{
             a: 0,
             b: "",
             c: 0,
             d: 0,
             e: 0,
             f: 0,
             g: [],
             h: [],
             i: [],
             y: [0, 1, 2, 3, 10_000]
           }
  end

  test "Sub.z, overflow values > MAX UINT32" do
    #  <<130, 128, etc. == 4294967298
    bytes = <<136, 241, 4, 130, 128, 128, 128, 16>>
    assert Sub.decode!(bytes) == %Sub{z: 1}
  end

  test "Sub.zz, overflow values > MAX UINT64" do
    #  <<130, 128, 128, 128, 1>> == 309485009821345068724781056
    bytes = <<144, 241, 4, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 32>>
    assert Sub.decode!(bytes) == %Sub{zz: 0}
  end

  test "Sub.map1/map2" do
    bytes =
      <<202, 131, 6, 13, 9, 255, 255, 255, 255, 255, 255, 255, 255, 18, 2, 1, 2, 202, 131, 6, 13,
        9, 0, 0, 0, 0, 0, 0, 0, 0, 18, 2, 3, 4, 210, 131, 6, 13, 9, 0, 0, 0, 0, 0, 0, 0, 0, 18, 2,
        5, 6, 210, 131, 6, 13, 9, 1, 0, 0, 0, 0, 0, 0, 0, 18, 2, 7, 8>>

    assert Sub.decode!(bytes) == %Sub{
             map1: %{-1 => <<1, 2>>, 0 => <<3, 4>>},
             map2: %{0 => <<5, 6>>, 1 => <<7, 8>>}
           }
  end

  test "Msg.msg_a" do
    bytes = <<218, 1, 7, 0, 2, 3, 6, 159, 156, 1>>
    assert Msg.decode!(bytes) == %Msg{msg_a: [0, 1, -2, 3, -10_000]}
  end

  test "Msg.msg_b" do
    bytes =
      <<226, 1, 20, 0, 0, 0, 0, 1, 0, 0, 0, 254, 255, 255, 255, 3, 0, 0, 0, 240, 216, 255, 255>>

    assert Msg.decode!(bytes) == %Msg{msg_b: [0, 1, 4_294_967_294, 3, 4_294_957_296]}
  end

  test "Msg.msg_c" do
    bytes =
      <<234, 1, 40, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 254, 255, 255, 255, 255, 255,
        255, 255, 3, 0, 0, 0, 0, 0, 0, 0, 240, 216, 255, 255, 255, 255, 255, 255>>

    assert Msg.decode!(bytes) == %Msg{msg_c: [0, 1, -2, 3, -10_000]}
  end

  test "Msg.msg_Sub.a" do
    bytes = <<26, 3, 8, 150, 1>>

    assert Msg.decode!(bytes) == %Msg{
             msg_d: :FOO,
             msg_e: false,
             msg_f: %Sub{a: 150, b: ""},
             msg_g: [],
             msg_h: 0.0,
             msg_i: [],
             msg_j: [],
             msg_k: %{}
           }
  end

  test "Msg.msg_Sub.a; Msg.msg_Sub.b" do
    bytes = <<26, 12, 8, 150, 1, 18, 7, 116, 101, 115, 116, 105, 110, 103>>

    assert Msg.decode!(bytes) == %Msg{
             msg_d: :FOO,
             msg_e: false,
             msg_f: %Sub{a: 150, b: "testing"},
             msg_g: [],
             msg_h: 0.0,
             msg_i: [],
             msg_j: [],
             msg_k: %{}
           }
  end

  test "Msg.msg_g" do
    bytes = <<34, 6, 3, 142, 2, 158, 167, 5>>

    assert Msg.decode!(bytes) == %Msg{
             msg_d: :FOO,
             msg_e: false,
             msg_f: nil,
             msg_g: [3, 270, 86_942],
             msg_h: 0.0,
             msg_i: [],
             msg_j: [],
             msg_k: %{}
           }
  end

  test "Msg.msg_g (unpacked)" do
    bytes = <<32, 1, 32, 2, 32, 3>>

    assert Msg.decode!(bytes) == %Msg{
             msg_d: :FOO,
             msg_e: false,
             msg_f: nil,
             msg_g: [1, 2, 3],
             msg_h: 0.0,
             msg_i: [],
             msg_j: [],
             msg_k: %{}
           }
  end

  test "Msg.msg_Sub.a; Msg.msg_Sub.b; Msg.msg_g" do
    bytes =
      <<26, 12, 8, 150, 1, 18, 7, 116, 101, 115, 116, 105, 110, 103, 34, 6, 3, 142, 2, 158, 167,
        5>>

    assert Msg.decode!(bytes) == %Msg{
             msg_d: :FOO,
             msg_e: false,
             msg_f: %Sub{a: 150, b: "testing"},
             msg_g: [3, 270, 86_942],
             msg_h: 0.0,
             msg_i: [],
             msg_j: [],
             msg_k: %{}
           }
  end

  test "Msg.msg_e" do
    bytes = <<16, 1>>

    assert Msg.decode!(bytes) == %Msg{
             msg_d: :FOO,
             msg_e: true,
             msg_f: nil,
             msg_g: [],
             msg_h: 0.0,
             msg_i: [],
             msg_j: [],
             msg_k: %{}
           }
  end

  test "Msg.msg_h" do
    bytes = <<41, 246, 40, 92, 143, 194, 181, 64, 192>>

    assert Msg.decode!(bytes) == %Msg{
             msg_d: :FOO,
             msg_e: false,
             msg_f: nil,
             msg_g: [],
             msg_h: -33.42,
             msg_i: [],
             msg_j: [],
             msg_k: %{}
           }
  end

  test "Msg.msg_i" do
    bytes = <<50, 8, 0, 0, 128, 63, 0, 0, 0, 64>>

    assert Msg.decode!(bytes) == %Msg{
             msg_d: :FOO,
             msg_e: false,
             msg_f: nil,
             msg_g: [],
             msg_h: 0.0,
             msg_i: [1.0, 2.0],
             msg_j: [],
             msg_k: %{}
           }
  end

  test "Msg.msg_i, infinity, -infinity" do
    bytes = <<50, 8, 0, 0, 0x80, 0x7F, 0, 0, 0x80, 0xFF>>

    assert Msg.decode!(bytes) == %Msg{
             msg_d: :FOO,
             msg_e: false,
             msg_f: nil,
             msg_g: [],
             msg_h: 0.0,
             msg_i: [:infinity, :"-infinity"],
             msg_j: [],
             msg_k: %{}
           }
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

  test "Msg.msg_d" do
    bytes = <<8, 1>>

    assert Msg.decode!(bytes) == %Msg{
             msg_d: :BAR,
             msg_e: false,
             msg_f: nil,
             msg_g: [],
             msg_h: 0.0,
             msg_i: [],
             msg_j: [],
             msg_k: %{}
           }
  end

  test "Msg.msg_d, unknown enum entry" do
    bytes = <<8, 2>>

    assert Msg.decode!(bytes) == %Msg{
             msg_d: 2,
             msg_e: false,
             msg_f: nil,
             msg_g: [],
             msg_h: 0.0,
             msg_i: [],
             msg_j: [],
             msg_k: %{}
           }
  end

  test "Msg.msg_j" do
    bytes = <<58, 3, 8, 146, 6, 58, 5, 18, 3, 102, 111, 111>>

    assert Msg.decode!(bytes) == %Msg{
             msg_d: :FOO,
             msg_e: false,
             msg_f: nil,
             msg_g: [],
             msg_h: 0.0,
             msg_i: [],
             msg_j: [%Sub{a: 786}, %Sub{b: "foo"}],
             msg_k: %{}
           }
  end

  test "Msg.msg_k" do
    bytes = <<66, 7, 8, 2, 18, 3, 98, 97, 114, 66, 7, 8, 1, 18, 3, 102, 111, 111>>

    assert Msg.decode!(bytes) == %Msg{
             msg_d: :FOO,
             msg_e: false,
             msg_f: nil,
             msg_g: [],
             msg_h: 0.0,
             msg_i: [],
             msg_j: [],
             msg_k: %{1 => "foo", 2 => "bar"}
           }
  end

  test "Msg.msg_k, duplicate key, last one is kept" do
    #                   1 => "foo"                         1 => "bar"
    bytes = <<66, 7, 8, 1, 18, 3, 102, 111, 111, 66, 7, 8, 1, 18, 3, 98, 97, 114>>

    assert Msg.decode!(bytes) == %Msg{
             msg_k: %{1 => "bar"}
           }
  end

  test "Msg.msg_k, with unknown data in map entry" do
    bytes = <<66, 7, 8, 2, 18, 3, 98, 97, 114, 66, 10, 8, 1, 18, 3, 102, 111, 111, 26, 1, 102>>

    assert Msg.decode!(bytes) == %Msg{
             msg_d: :FOO,
             msg_e: false,
             msg_f: nil,
             msg_g: [],
             msg_h: 0.0,
             msg_i: [],
             msg_j: [],
             msg_k: %{1 => "foo", 2 => "bar"}
           }
  end

  test "Msg.msg_k (reversed)" do
    bytes = <<66, 7, 8, 1, 18, 3, 102, 111, 111, 66, 7, 8, 2, 18, 3, 98, 97, 114>>

    assert Msg.decode!(bytes) == %Msg{
             msg_d: :FOO,
             msg_e: false,
             msg_f: nil,
             msg_g: [],
             msg_h: 0.0,
             msg_i: [],
             msg_j: [],
             msg_k: %{1 => "foo", 2 => "bar"}
           }
  end

  test "Msg.msg_k (reversed inside map entry)" do
    bytes = <<66, 7, 18, 3, 98, 97, 114, 8, 2, 66, 7, 8, 1, 18, 3, 102, 111, 111>>

    assert Msg.decode!(bytes) == %Msg{
             msg_d: :FOO,
             msg_e: false,
             msg_f: nil,
             msg_g: [],
             msg_h: 0.0,
             msg_i: [],
             msg_j: [],
             msg_k: %{1 => "foo", 2 => "bar"}
           }
  end

  test "Msg.msg_k, missing key" do
    bytes = <<66, 5, 18, 3, 102, 111, 111>>

    assert Msg.decode!(bytes) == %Msg{msg_k: %{0 => "foo"}}
  end

  test "Msg.msg_k, missing value" do
    bytes = <<66, 2, 8, 1>>

    assert Msg.decode!(bytes) == %Msg{msg_k: %{1 => ""}}
  end

  test "Upper.msg_map, missing message value" do
    bytes = <<18, 5, 10, 3, 102, 111, 111>>

    assert Upper.decode!(bytes) == %Upper{msg_map: %{"foo" => %Msg{}}}
  end

  test "Msg.msg_l" do
    bytes =
      <<74, 14, 10, 3, 98, 97, 114, 17, 0, 0, 0, 0, 0, 0, 240, 63, 74, 14, 10, 3, 102, 111, 111,
        17, 154, 153, 153, 153, 153, 153, 69, 64>>

    assert Msg.decode!(bytes) == %Msg{
             msg_d: :FOO,
             msg_e: false,
             msg_f: nil,
             msg_g: [],
             msg_h: 0.0,
             msg_i: [],
             msg_j: [],
             msg_k: %{},
             msg_l: %{"bar" => 1.0, "foo" => 43.2}
           }
  end

  test "Msg.msg_m, empty" do
    bytes = ""

    assert Msg.decode!(bytes) == %Msg{
             msg_d: :FOO,
             msg_e: false,
             msg_f: nil,
             msg_g: [],
             msg_h: 0.0,
             msg_i: [],
             msg_j: [],
             msg_k: %{},
             msg_l: %{},
             msg_m: nil
           }
  end

  test "Msg.msg_m, string" do
    bytes = <<82, 3, 98, 97, 114>>

    assert Msg.decode!(bytes) == %Msg{
             msg_d: :FOO,
             msg_e: false,
             msg_f: nil,
             msg_g: [],
             msg_h: 0.0,
             msg_i: [],
             msg_j: [],
             msg_k: %{},
             msg_l: %{},
             msg_m: {:msg_n, "bar"}
           }
  end

  test "Msg.msg_m, Sub" do
    bytes = <<90, 2, 8, 42>>

    assert Msg.decode!(bytes) == %Msg{
             msg_d: :FOO,
             msg_e: false,
             msg_f: nil,
             msg_g: [],
             msg_h: 0.0,
             msg_i: [],
             msg_j: [],
             msg_k: %{},
             msg_l: %{},
             msg_m: {:msg_o, %Sub{a: 42}}
           }
  end

  test "Msg.msg_m, several fields on the wire, keep the last one" do
    bytes = <<90, 2, 8, 42, 82, 3, 98, 97, 114, 82, 3, 98, 97, 114>>

    assert Msg.decode!(bytes) == %Msg{
             msg_d: :FOO,
             msg_e: false,
             msg_f: nil,
             msg_g: [],
             msg_h: 0.0,
             msg_i: [],
             msg_j: [],
             msg_k: %{},
             msg_l: %{},
             msg_m: {:msg_n, "bar"}
           }
  end

  test "Upper.msg.f" do
    bytes = <<10, 4, 26, 2, 8, 42>>

    assert Upper.decode!(bytes) == %Upper{
             msg: %Msg{
               msg_d: :FOO,
               msg_e: false,
               msg_f: %Sub{a: 42},
               msg_g: [],
               msg_h: 0.0,
               msg_i: [],
               msg_j: []
             }
           }
  end

  test "Upper.msg_map" do
    bytes = <<18, 9, 10, 3, 102, 111, 111, 18, 2, 8, 1, 18, 9, 10, 3, 98, 97, 122, 18, 2, 16, 1>>

    assert Upper.decode!(bytes) == %Upper{
             msg: nil,
             msg_map: %{
               "foo" => %Msg{
                 msg_d: :BAR,
                 msg_e: false,
                 msg_f: nil,
                 msg_g: [],
                 msg_h: 0.0,
                 msg_i: [],
                 msg_j: [],
                 msg_k: %{},
                 msg_l: %{},
                 msg_m: nil
               },
               "baz" => %Msg{
                 msg_d: :FOO,
                 msg_e: true,
                 msg_f: nil,
                 msg_g: [],
                 msg_h: 0.0,
                 msg_i: [],
                 msg_j: [],
                 msg_k: %{},
                 msg_l: %{},
                 msg_m: nil
               }
             }
           }
  end

  test "Upper.empty" do
    bytes = <<26, 0>>
    assert Upper.decode!(bytes) == %Upper{empty: %Empty{}}
  end

  test "Empty" do
    bytes = <<>>
    assert Empty.decode!(bytes) == %Empty{}
  end

  test "Empty, unknown fields" do
    bytes = <<8, 42, 25, 246, 40, 92, 143, 194, 53, 69, 64, 136, 241, 4, 83>>

    assert Empty.decode!(bytes) == %Empty{
             __uf__: [
               {10_001, 0, "S"},
               {3, 1, <<246, 40, 92, 143, 194, 53, 69, 64>>},
               {1, 0, "*"}
             ]
           }
  end

  test "Error when required field is missing" do
    assert {:error, %Protox.RequiredFieldsError{missing_fields: fs}} = Required.decode(<<>>)
    assert fs == [:a]
  end

  test "Required field" do
    assert Required.decode!(<<8, 0>>) == %Required{a: 0}
    assert Required.decode!(<<8, 1>>) == %Required{a: 1}
  end

  test "No name clash for __uf__" do
    assert NoNameClash.decode!(<<>>) == %NoNameClash{__uf__: 0}
  end

  test "Protobuf2, all fields unset" do
    bytes = <<>>
    assert Protobuf2.decode!(bytes) == %Protobuf2{a: nil, s: nil, t: nil}
  end

  test "Protobuf2.s" do
    bytes = <<200, 1, 2>>
    assert Protobuf2.decode!(bytes) == %Protobuf2{s: :TWO}
  end

  test "Protobuf2.t, optional is nil when not set" do
    bytes = <<>>
    assert Protobuf2.decode!(bytes) == %Protobuf2{t: nil}
  end

  test "Protobuf2.a, repeated scalar, select last" do
    bytes = <<8, 150, 1, 8, 1>>
    assert Protobuf2.decode!(bytes) == %Protobuf2{a: 1}
  end

  test "Required.Proto3.ProtobufInput.ValidDataOneof.MESSAGE.Merge" do
    req1 = <<130, 7, 9, 18, 7, 8, 1, 16, 1, 200, 5, 1>>
    req2 = <<130, 7, 7, 18, 5, 16, 1, 200, 5, 1>>
    req = req1 <> req2

    m1 = CoRecursive.decode!(req1)
    m2 = CoRecursive.decode!(req2)
    m = CoRecursive.decode!(req)

    # https://developers.google.com/protocol-buffers/docs/encoding#optional
    assert m == Protox.Message.merge(m1, m2)
  end

  test "Decoding! a field with tag 0 raises IllegalTagError" do
    assert_raise Protox.IllegalTagError, "Field with illegal tag 0", fn ->
      Msg.decode!(<<0>>)
    end
  end

  test "Decoding a field with tag 0 returns an error" do
    assert {:error, %Protox.IllegalTagError{}} = Empty.decode(<<0>>)
  end

  test "Decode dummy varint data returns an error" do
    assert {:error, %Protox.DecodingError{reason: :varint}} = Empty.decode(<<255, 255, 255, 255>>)
  end

  test "Decode! dummy varint data raises DecodingError" do
    exception =
      assert_raise Protox.DecodingError, ~r/^Could not decode data/, fn ->
        Empty.decode!(<<255, 255, 255, 255>>)
      end

    assert exception.reason == :varint
  end

  test "Raise when required field is missing" do
    exception =
      assert_raise Protox.RequiredFieldsError, "Some required fields are not set: [:a]", fn ->
        Required.decode!(<<>>)
      end

    assert exception.missing_fields == [:a]
  end
end
