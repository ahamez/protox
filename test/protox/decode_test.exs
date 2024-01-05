# A dedicated module to make sure all messages are compiled before Protox.DecodeTest.
defmodule Protox.DecodeTestMessages do
  Code.require_file("./test/support/messages.exs")
end

defmodule Protox.DecodeTest do
  use ExUnit.Case

  @success_tests [
    {
      "Sub.a",
      <<8, 150, 1>>,
      %Sub{a: 150, b: ""}
    },
    {
      "Sub.a, repeated scalar, select last",
      <<8, 150, 1, 8, 1, 8, 150, 1, 8, 2>>,
      %Sub{a: 2, b: ""}
    },
    {
      "Sub.a, negative 64 bits",
      <<8, 234, 254, 255, 255, 255, 255, 255, 255, 255, 1>>,
      %Sub{a: -150, b: ""}
    },
    {
      "Sub.a, negative 32 bits",
      <<8, 234, 254, 255, 255, 15>>,
      %Sub{a: -150, b: ""}
    },
    {
      "Sub.b",
      <<18, 7, 116, 101, 115, 116, 105, 110, 103>>,
      %Sub{a: 0, b: "testing"}
    },
    {
      "Sub.b, empty",
      <<18, 0>>,
      %Sub{a: 0, b: ""}
    },
    {
      "Sub.a; Sub.b",
      <<8, 150, 1, 18, 7, 116, 101, 115, 116, 105, 110, 103>>,
      %Sub{a: 150, b: "testing"}
    },
    {
      "Sub.a; Sub.b; Sub.z",
      <<8, 150, 1, 18, 7, 116, 101, 115, 116, 105, 110, 103, 136, 241, 4, 157, 156, 1>>,
      %Sub{a: 150, b: "testing", z: -9999}
    },
    {
      "Sub.b; Sub.a",
      <<18, 7, 116, 101, 115, 116, 105, 110, 103, 8, 150, 1>>,
      %Sub{a: 150, b: "testing"}
    },
    {
      "Sub, unknown tag (double)",
      <<8, 42, 25, 246, 40, 92, 143, 194, 53, 69, 64, 136, 241, 4, 83>>,
      %Sub{
        a: 42,
        b: "",
        z: -42,
        __uf__: [{3, 1, <<246, 40, 92, 143, 194, 53, 69, 64>>}]
      }
    },
    {
      "Sub, unknown tag (embedded message)",
      <<8, 42, 34, 0, 136, 241, 4, 83>>,
      %Sub{a: 42, b: "", z: -42, __uf__: [{4, 2, <<>>}]}
    },
    {
      "Sub, unknown tag (string)",
      <<8, 42, 42, 4, 121, 97, 121, 101, 136, 241, 4, 83>>,
      %Sub{
        a: 42,
        b: "",
        z: -42,
        __uf__: [{5, 2, <<121, 97, 121, 101>>}]
      }
    },
    {
      "Sub, unknown tag (bytes)",
      <<8, 142, 26, 82, 4, 104, 101, 121, 33, 136, 241, 4, 19>>,
      %Sub{
        a: 3342,
        b: "",
        z: -10,
        __uf__: [{10, 2, <<104, 101, 121, 33>>}]
      }
    },
    {
      "Sub, unknown tag (varint)",
      <<8, 142, 26, 82, 4, 104, 101, 121, 33, 88, 154, 5, 136, 241, 4, 19>>,
      %Sub{
        a: 3342,
        b: "",
        z: -10,
        __uf__: [{11, 0, <<154, 5>>}, {10, 2, <<104, 101, 121, 33>>}]
      }
    },
    {
      "Sub, unknown tag (float)",
      <<8, 142, 26, 82, 4, 104, 101, 121, 33, 88, 154, 5, 101, 236, 81, 5, 66, 136, 241, 4, 19>>,
      %Sub{
        a: 3342,
        b: "",
        z: -10,
        __uf__: [
          {12, 5, <<236, 81, 5, 66>>},
          {11, 0, <<154, 5>>},
          {10, 2, <<104, 101, 121, 33>>}
        ]
      }
    },
    {
      "Sub.c",
      <<48, 212, 253, 255, 255, 255, 255, 255, 255, 255, 1>>,
      %Sub{a: 0, b: "", c: -300}
    },
    {
      "Sub.d; Sub.e",
      <<56, 133, 7, 64, 177, 3>>,
      %Sub{a: 0, b: "", c: 0, d: 901, e: 433}
    },
    {
      "Sub.d, overflow values > MAX UINT32",
      #  <<128, 128, 128, 128, 32>> == 8589934592
      <<56, 128, 128, 128, 128, 32>>,
      %Sub{d: 0}
    },
    {
      "Sub.f",
      <<72, 213, 20>>,
      %Sub{a: 0, b: "", c: 0, d: 0, e: 0, f: -1323}
    },
    {"Sub.g", <<106, 16, 1, 0, 0, 0, 0, 0, 0, 0, 254, 255, 255, 255, 255, 255, 255, 255>>,
     %Sub{
       a: 0,
       b: "",
       c: 0,
       d: 0,
       e: 0,
       f: 0,
       g: [1, 18_446_744_073_709_551_614],
       h: [],
       i: []
     }},
    {
      "Sub.g, not contiguous, should be concatenated",
      <<106, 8, 1, 0, 0, 0, 0, 0, 0, 0, 8, 150, 1, 106, 8, 254, 255, 255, 255, 255, 255, 255,
        255>>,
      %Sub{
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
    },
    {
      "Sub.g; Sub.h; Sub.i",
      <<106, 8, 0, 0, 0, 0, 0, 0, 0, 0, 114, 4, 255, 255, 255, 255, 122, 16, 154, 153, 153, 153,
        153, 153, 64, 64, 0, 0, 0, 0, 0, 0, 70, 192>>,
      %Sub{
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
    },
    {
      "Sub.i, infinity",
      <<122, 8, 0, 0, 0, 0, 0, 0, 0xF0, 0x7F>>,
      %Sub{i: [:infinity]}
    },
    {
      "Sub.i, -infinity",
      <<122, 8, 0, 0, 0, 0, 0, 0, 0xF0, 0xFF>>,
      %Sub{i: [:"-infinity"]}
    },
    {
      "Sub.i, nan",
      <<122, 24, 0x01, 0, 0, 0, 0, 0, 0xF0, 0x7F, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
        0, 0, 0, 0, 0, 0, 0xF8, 0xFF>>,
      %Sub{i: [:nan, :nan, :nan]}
    },
    {
      "Sub.h",
      <<114, 8, 255, 255, 255, 255, 254, 255, 255, 255>>,
      %Sub{
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
    },
    {
      "Sub.j, unpacked in definition",
      <<128, 1, 1, 128, 1, 2, 128, 1, 3>>,
      %Sub{j: [1, 2, 3]}
    },
    {
      "Sub.n",
      <<162, 1, 4, 1, 0, 0, 1>>,
      %Sub{
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
    },
    {
      "Sub.n (all false)",
      <<162, 1, 4, 0, 0, 0, 0>>,
      %Sub{
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
    },
    {
      "Sub.o ",
      <<170, 1, 3, 0, 1, 0>>,
      %Sub{
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
    },
    {
      "Sub.o (unknown entry) ",
      <<170, 1, 4, 0, 1, 0, 2>>,
      %Sub{
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
    },
    {
      "Sub.p",
      <<176, 1, 1, 176, 1, 0, 176, 1, 1, 176, 1, 0>>,
      %Sub{
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
    },
    {
      "Sub.p, not contiguous, should be concatenated",
      <<176, 1, 1, 176, 1, 0, 8, 150, 1, 176, 1, 1, 176, 1, 0>>,
      %Sub{
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
    },
    {
      "Sub.p, packed and unpacked, should be concatenated (1)",
      # packed <> unpacked
      <<178, 1, 2, 1, 0>> <> <<176, 1, 1, 176, 1, 0>>,
      %Sub{p: [true, false, true, false]}
    },
    {
      "Sub.p, packed and unpacked, should be concatenated (2)",
      # unpacked <> packed
      <<176, 1, 1, 176, 1, 0>> <> <<178, 1, 2, 1, 0>>,
      %Sub{p: [true, false, true, false]}
    },
    {
      "Sub.q (unpacked in definition)",
      <<184, 1, 0, 184, 1, 1, 184, 1, 1, 184, 1, 0>>,
      %Sub{
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
    },
    {
      "Sub.q (unpacked in definition, with unknown values)",
      <<184, 1, 0, 184, 1, 1, 184, 1, 2, 184, 1, 0>>,
      %Sub{
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
    },
    {
      "Sub.r, negative constant",
      <<192, 1, 255, 255, 255, 255, 255, 255, 255, 255, 255, 1>>,
      %Sub{r: :NEG}
    },
    {
      "Sub.u",
      <<218, 1, 6, 0, 1, 2, 3, 144, 78>>,
      %Sub{
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
    },
    {
      "Sub.w",
      <<226, 1, 7, 0, 1, 4, 5, 160, 156, 1>>,
      %Sub{
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
    },
    {
      "Sub.x",
      <<234, 1, 24, 0, 255, 255, 255, 255, 255, 255, 255, 255, 255, 1, 2, 253, 255, 255, 255, 255,
        255, 255, 255, 255, 1, 144, 78>>,
      %Sub{
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
    },
    {
      "Sub.y",
      <<242, 1, 6, 0, 1, 2, 3, 144, 78>>,
      %Sub{
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
    },
    {
      "Sub.z, overflow values > MAX UINT32",
      #  <<130, 128, etc. == 4294967298
      <<136, 241, 4, 130, 128, 128, 128, 16>>,
      %Sub{z: 1}
    },
    {
      "Sub.zz, overflow values > MAX UINT64",
      #  <<130, 128, 128, 128, 1>> == 309485009821345068724781056
      <<144, 241, 4, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 32>>,
      %Sub{zz: 0}
    },
    {
      "Sub.map1/map2",
      <<202, 131, 6, 13, 9, 255, 255, 255, 255, 255, 255, 255, 255, 18, 2, 1, 2, 202, 131, 6, 13,
        9, 0, 0, 0, 0, 0, 0, 0, 0, 18, 2, 3, 4, 210, 131, 6, 13, 9, 0, 0, 0, 0, 0, 0, 0, 0, 18, 2,
        5, 6, 210, 131, 6, 13, 9, 1, 0, 0, 0, 0, 0, 0, 0, 18, 2, 7, 8>>,
      %Sub{
        map1: %{-1 => <<1, 2>>, 0 => <<3, 4>>},
        map2: %{0 => <<5, 6>>, 1 => <<7, 8>>}
      }
    },
    {
      "Msg.msg_a",
      <<218, 1, 7, 0, 2, 3, 6, 159, 156, 1>>,
      %Msg{msg_a: [0, 1, -2, 3, -10_000]}
    },
    {
      "Msg.msg_b",
      <<226, 1, 20, 0, 0, 0, 0, 1, 0, 0, 0, 254, 255, 255, 255, 3, 0, 0, 0, 240, 216, 255, 255>>,
      %Msg{msg_b: [0, 1, 4_294_967_294, 3, 4_294_957_296]}
    },
    {
      "Msg.msg_c",
      <<234, 1, 40, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 254, 255, 255, 255, 255, 255,
        255, 255, 3, 0, 0, 0, 0, 0, 0, 0, 240, 216, 255, 255, 255, 255, 255, 255>>,
      %Msg{msg_c: [0, 1, -2, 3, -10_000]}
    },
    {
      "Msg.msg_Sub.a",
      <<26, 3, 8, 150, 1>>,
      %Msg{
        msg_d: :FOO,
        msg_e: false,
        msg_f: %Sub{a: 150, b: ""},
        msg_g: [],
        msg_h: 0.0,
        msg_i: [],
        msg_j: [],
        msg_k: %{}
      }
    },
    {
      "Msg.msg_Sub.a; Msg.msg_Sub.b",
      <<26, 12, 8, 150, 1, 18, 7, 116, 101, 115, 116, 105, 110, 103>>,
      %Msg{
        msg_d: :FOO,
        msg_e: false,
        msg_f: %Sub{a: 150, b: "testing"},
        msg_g: [],
        msg_h: 0.0,
        msg_i: [],
        msg_j: [],
        msg_k: %{}
      }
    },
    {
      "Msg.msg_g",
      <<34, 6, 3, 142, 2, 158, 167, 5>>,
      %Msg{
        msg_d: :FOO,
        msg_e: false,
        msg_f: nil,
        msg_g: [3, 270, 86_942],
        msg_h: 0.0,
        msg_i: [],
        msg_j: [],
        msg_k: %{}
      }
    },
    {
      "Msg.msg_g (unpacked)",
      <<32, 1, 32, 2, 32, 3>>,
      %Msg{
        msg_d: :FOO,
        msg_e: false,
        msg_f: nil,
        msg_g: [1, 2, 3],
        msg_h: 0.0,
        msg_i: [],
        msg_j: [],
        msg_k: %{}
      }
    },
    {
      "Msg.msg_Sub.a; Msg.msg_Sub.b; Msg.msg_g",
      <<26, 12, 8, 150, 1, 18, 7, 116, 101, 115, 116, 105, 110, 103, 34, 6, 3, 142, 2, 158, 167,
        5>>,
      %Msg{
        msg_d: :FOO,
        msg_e: false,
        msg_f: %Sub{a: 150, b: "testing"},
        msg_g: [3, 270, 86_942],
        msg_h: 0.0,
        msg_i: [],
        msg_j: [],
        msg_k: %{}
      }
    },
    {
      "Msg.msg_e",
      <<16, 1>>,
      %Msg{
        msg_d: :FOO,
        msg_e: true,
        msg_f: nil,
        msg_g: [],
        msg_h: 0.0,
        msg_i: [],
        msg_j: [],
        msg_k: %{}
      }
    },
    {
      "Msg.msg_h",
      <<41, 246, 40, 92, 143, 194, 181, 64, 192>>,
      %Msg{
        msg_d: :FOO,
        msg_e: false,
        msg_f: nil,
        msg_g: [],
        msg_h: -33.42,
        msg_i: [],
        msg_j: [],
        msg_k: %{}
      }
    },
    {
      "Msg.msg_i",
      <<50, 8, 0, 0, 128, 63, 0, 0, 0, 64>>,
      %Msg{
        msg_d: :FOO,
        msg_e: false,
        msg_f: nil,
        msg_g: [],
        msg_h: 0.0,
        msg_i: [1.0, 2.0],
        msg_j: [],
        msg_k: %{}
      }
    },
    {
      "Msg.msg_i, infinity, -infinity",
      <<50, 8, 0, 0, 0x80, 0x7F, 0, 0, 0x80, 0xFF>>,
      %Msg{
        msg_d: :FOO,
        msg_e: false,
        msg_f: nil,
        msg_g: [],
        msg_h: 0.0,
        msg_i: [:infinity, :"-infinity"],
        msg_j: [],
        msg_k: %{}
      }
    },
    {
      "Msg.msg_i, nan",
      <<50, 12, 0x01, 0, 0x80, 0x7F, 0, 0, 0xC0, 0xFF, 0xFF, 0xFF, 0xFF, 0x7F>>,
      %Msg{
        msg_d: :FOO,
        msg_e: false,
        msg_f: nil,
        msg_g: [],
        msg_h: 0.0,
        msg_i: [:nan, :nan, :nan],
        msg_j: [],
        msg_k: %{}
      }
    },
    {"Msg.msg_d", <<8, 1>>,
     %Msg{
       msg_d: :BAR,
       msg_e: false,
       msg_f: nil,
       msg_g: [],
       msg_h: 0.0,
       msg_i: [],
       msg_j: [],
       msg_k: %{}
     }},
    {
      "Msg.msg_d, unknown enum entry",
      <<8, 2>>,
      %Msg{
        msg_d: 2,
        msg_e: false,
        msg_f: nil,
        msg_g: [],
        msg_h: 0.0,
        msg_i: [],
        msg_j: [],
        msg_k: %{}
      }
    },
    {
      "Msg.msg_j",
      <<58, 3, 8, 146, 6, 58, 5, 18, 3, 102, 111, 111>>,
      %Msg{
        msg_d: :FOO,
        msg_e: false,
        msg_f: nil,
        msg_g: [],
        msg_h: 0.0,
        msg_i: [],
        msg_j: [%Sub{a: 786}, %Sub{b: "foo"}],
        msg_k: %{}
      }
    },
    {
      "Msg.msg_k",
      <<66, 7, 8, 2, 18, 3, 98, 97, 114, 66, 7, 8, 1, 18, 3, 102, 111, 111>>,
      %Msg{
        msg_d: :FOO,
        msg_e: false,
        msg_f: nil,
        msg_g: [],
        msg_h: 0.0,
        msg_i: [],
        msg_j: [],
        msg_k: %{1 => "foo", 2 => "bar"}
      }
    },
    {
      "Msg.msg_k, duplicate key, last one is kept",
      #                  1: "f"  "o"  "o"                   1: "b" "a" "r"
      <<66, 7, 8, 1, 18, 3, 102, 111, 111, 66, 7, 8, 1, 18, 3, 98, 97, 114>>,
      %Msg{
        msg_k: %{1 => "bar"}
      }
    },
    {
      "Msg.msg_k, with unknown data in map entry",
      <<66, 7, 8, 2, 18, 3, 98, 97, 114, 66, 10, 8, 1, 18, 3, 102, 111, 111, 26, 1, 102>>,
      %Msg{
        msg_d: :FOO,
        msg_e: false,
        msg_f: nil,
        msg_g: [],
        msg_h: 0.0,
        msg_i: [],
        msg_j: [],
        msg_k: %{1 => "foo", 2 => "bar"}
      }
    },
    {
      "Msg.msg_k (reversed)",
      <<66, 7, 8, 1, 18, 3, 102, 111, 111, 66, 7, 8, 2, 18, 3, 98, 97, 114>>,
      %Msg{
        msg_d: :FOO,
        msg_e: false,
        msg_f: nil,
        msg_g: [],
        msg_h: 0.0,
        msg_i: [],
        msg_j: [],
        msg_k: %{1 => "foo", 2 => "bar"}
      }
    },
    {
      "Msg.msg_k (reversed inside map entry)",
      <<66, 7, 18, 3, 98, 97, 114, 8, 2, 66, 7, 8, 1, 18, 3, 102, 111, 111>>,
      %Msg{
        msg_d: :FOO,
        msg_e: false,
        msg_f: nil,
        msg_g: [],
        msg_h: 0.0,
        msg_i: [],
        msg_j: [],
        msg_k: %{1 => "foo", 2 => "bar"}
      }
    },
    {
      "Msg.msg_k, missing key",
      <<66, 5, 18, 3, 102, 111, 111>>,
      %Msg{msg_k: %{0 => "foo"}}
    },
    {
      "Msg.msg_k, missing value",
      <<66, 2, 8, 1>>,
      %Msg{msg_k: %{1 => ""}}
    },
    {
      "Upper.msg_map, missing message value",
      <<18, 5, 10, 3, 102, 111, 111>>,
      %Upper{msg_map: %{"foo" => %Msg{}}}
    },
    {
      "Msg.msg_l",
      <<74, 14, 10, 3, 98, 97, 114, 17, 0, 0, 0, 0, 0, 0, 240, 63, 74, 14, 10, 3, 102, 111, 111,
        17, 154, 153, 153, 153, 153, 153, 69, 64>>,
      %Msg{
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
    },
    {
      "Msg.msg_m, empty",
      "",
      %Msg{
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
    },
    {
      "Msg.msg_m, string",
      <<82, 3, 98, 97, 114>>,
      %Msg{
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
    },
    {
      "Msg.msg_m, Sub",
      <<90, 2, 8, 42>>,
      %Msg{
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
    },
    {
      "Msg.msg_m, several fields on the wire, keep the last one",
      <<90, 2, 8, 42, 82, 3, 98, 97, 114, 82, 3, 98, 97, 114>>,
      %Msg{
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
    },
    {
      "Upper.msg.f",
      <<10, 4, 26, 2, 8, 42>>,
      %Upper{
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
    },
    {
      "Upper.msg_map",
      <<18, 9, 10, 3, 102, 111, 111, 18, 2, 8, 1, 18, 9, 10, 3, 98, 97, 122, 18, 2, 16, 1>>,
      %Upper{
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
    },
    {
      "Upper.empty",
      <<26, 0>>,
      %Upper{empty: %Empty{}}
    },
    {
      "Empty",
      <<>>,
      %Empty{}
    },
    {
      "Empty, unknown fields",
      <<8, 42, 25, 246, 40, 92, 143, 194, 53, 69, 64, 136, 241, 4, 83>>,
      %Empty{
        __uf__: [
          {10_001, 0, "S"},
          {3, 1, <<246, 40, 92, 143, 194, 53, 69, 64>>},
          {1, 0, "*"}
        ]
      }
    },
    {
      "Required fields (1)",
      <<8, 0>>,
      %Required{a: 0}
    },
    {
      "Required fields (2)",
      <<8, 1>>,
      %Required{a: 1}
    },
    {
      "No name clash for __uf__",
      <<>>,
      %NoNameClash{__uf__: 0}
    },
    {
      "Protobuf2, all fields unset",
      <<>>,
      %Protobuf2{a: nil, s: nil, t: nil}
    },
    {
      "Protobuf2.s",
      <<200, 1, 2>>,
      %Protobuf2{s: :TWO}
    },
    {
      "Protobuf2.t, optional is nil when not set",
      <<>>,
      %Protobuf2{t: nil}
    },
    {
      "Protobuf2.a, repeated scalar, select last",
      <<8, 150, 1, 8, 1>>,
      %Protobuf2{a: 1}
    },
    {
      "Optional sub message",
      <<10, 2, 8, 42>>,
      %OptionalUpperMsg{sub: %OptionalSubMsg{a: 42}}
    },
    {
      "Optional sub message set to nim",
      <<>>,
      %OptionalUpperMsg{sub: nil}
    },
    {
      "Empty string",
      <<10, 0>>,
      %StringsAreUTF8{}
    },
    {
      "Non-ascii string",
      <<10, 39, "hello, 漢字, 💻, 🏁, working fine">>,
      %StringsAreUTF8{a: "hello, 漢字, 💻, 🏁, working fine"}
    },
    {
      "Empty repeated string (first occurence)",
      <<18, 0, 18, 5, "hello">>,
      %StringsAreUTF8{b: ["", "hello"]}
    },
    {
      "Empty repeated string (second occurence)",
      <<18, 5, "hello", 18, 0>>,
      %StringsAreUTF8{b: ["hello", ""]}
    }
  ]

  @failure_tests [
    {
      "decoding a field with tag 0 raises IllegalTagError",
      <<0>>,
      Msg,
      Protox.IllegalTagError
    },
    {
      "decoding a empty struct field with tag 0 raises IllegalTagError",
      <<0>>,
      Empty,
      Protox.IllegalTagError
    },
    {
      "decoding a dummy varint returns an error",
      <<255, 255, 255, 255>>,
      Empty,
      Protox.DecodingError
    },
    {
      "invalid bytes for unknown delimited (len doesn't match)",
      <<18, 7, 116, 101, 115, 116>>,
      Empty,
      Protox.DecodingError
    },
    {
      "can't parse unknown bytes",
      <<41, 246, 40, 92, 181, 64, 192>>,
      Empty,
      Protox.DecodingError
    },
    {
      "invalid double",
      <<41, 246, 40, 92, 143, 194, 181, 64>>,
      Msg,
      Protox.DecodingError
    },
    {
      "invalid float",
      <<21, 0, 0, 128>>,
      FloatPrecision,
      Protox.DecodingError
    },
    {
      "invalid sfixed64",
      <<81, 0, 0, 0, 0, 0, 0, 0>>,
      ProtobufTestMessages.Proto3.TestAllTypesProto3,
      Protox.DecodingError
    },
    {
      "invalid fixed64",
      <<65, 0, 0, 0, 0, 0, 0, 0>>,
      ProtobufTestMessages.Proto3.TestAllTypesProto3,
      Protox.DecodingError
    },
    {
      "invalid sfixed32",
      <<73, 0, 0, 0>>,
      ProtobufTestMessages.Proto3.TestAllTypesProto3,
      Protox.DecodingError
    },
    {
      "invalid fixed32",
      <<57, 0, 0, 0>>,
      ProtobufTestMessages.Proto3.TestAllTypesProto3,
      Protox.DecodingError
    },
    {
      "invalid delimited (string)",
      <<114, 3, 0, 0>>,
      ProtobufTestMessages.Proto3.TestAllTypesProto3,
      Protox.DecodingError
    },
    {
      "invalid unknown varint bytes",
      # malformed varint as the first bit of 128 is '1', which
      # indicated that another byte should follow
      <<8, 128>>,
      Empty,
      Protox.DecodingError
    },
    {
      "invalid string (incomplete prefix)",
      # We set field nr 1 to the length delimited value <<128, ?a>>
      <<10, 2, 128, ?a>>,
      StringsAreUTF8,
      {Protox.DecodingError,
       quote do
         ~r/string is not valid UTF-8/
       end}
    },
    {
      "invalid string (incomplete suffix)",
      # We set field nr 1 to the length delimited value <<?a, 128>>
      <<10, 2, ?a, 128>>,
      StringsAreUTF8,
      {Protox.DecodingError,
       quote do
         ~r/string is not valid UTF-8/
       end}
    },
    {
      "invalid string (incomplete infix)",
      # We set field nr 1 to the length delimited value <<?a, 255, ?b>>
      <<10, 3, ?a, 255, ?b>>,
      StringsAreUTF8,
      {Protox.DecodingError,
       quote do
         ~r/string is not valid UTF-8/
       end}
    },
    {
      "invalid string (random data)",
      # We set field nr 1 to length delimited 64 bytes of random data
      <<10, 64>> <> :crypto.strong_rand_bytes(64),
      StringsAreUTF8,
      {Protox.DecodingError,
       quote do
         ~r/string is not valid UTF-8/
       end}
    },
    {
      "invalid repeated string (1st occurence)",
      # We set first occurence of field nr 2 to the length delimited value <<128>>
      <<
        18,
        2,
        128,
        18,
        1,
        "hello"
      >>,
      StringsAreUTF8,
      {Protox.DecodingError,
       quote do
         ~r/string is not valid UTF-8/
       end}
    },
    {
      "invalid repeated string (2nd occurance)",
      # We set second occurence of field nr 2 to the length delimited value <<128>>
      <<
        18,
        5,
        "hello",
        18,
        1,
        128
      >>,
      StringsAreUTF8,
      {Protox.DecodingError,
       quote do
         ~r/string is not valid UTF-8/
       end}
    }
  ]

  for {description, bytes, expected} <- @success_tests do
    test "Success: can decode #{description}" do
      bytes = unquote(bytes)
      expected = unquote(Macro.escape(expected))

      assert Protox.decode!(bytes, expected.__struct__) == expected
    end
  end

  for {description, bytes, mod, exception} <- @failure_tests do
    test "Failure: should not decode #{description}" do
      bytes = unquote(bytes)
      mod = unquote(mod)

      case unquote(exception) do
        {exception_mod, exception_msg} ->
          assert_raise exception_mod, exception_msg, fn ->
            Protox.decode!(bytes, mod)
          end

        exception_mod ->
          assert_raise exception_mod, fn ->
            Protox.decode!(bytes, mod)
          end
      end
    end
  end

  test "Required.Proto3.ProtobufInput.ValidDataOneof.MESSAGE.Merge" do
    req1 = <<130, 7, 9, 18, 7, 8, 1, 16, 1, 200, 5, 1>>
    req2 = <<130, 7, 7, 18, 5, 16, 1, 200, 5, 1>>
    req = req1 <> req2

    m1 = CoRecursive.decode!(req1)
    m2 = CoRecursive.decode!(req2)
    m = CoRecursive.decode!(req)

    # https://developers.google.com/protocol-buffers/docs/encoding#optional
    assert m == Protox.MergeMessage.merge(m1, m2)
  end

  test "failure: missing required fields" do
    assert {:error, %Protox.RequiredFieldsError{missing_fields: [:a]}} = Required.decode(<<>>)
  end
end
