defmodule Protox.Benchmarks.HandmadePayloads do
  def payloads() do
    [
      %Protox.Benchmarks.Sub{
        a: 150
      },
      %Protox.Benchmarks.Sub{
        a: -150
      },
      %Protox.Benchmarks.Sub{
        b: "testing"
      },
      %Protox.Benchmarks.Sub{
        a: 150,
        b: "testing"
      },
      %Protox.Benchmarks.Sub{
        a: 150,
        b: "testing",
        zzz: ""
      },
      %Protox.Benchmarks.Sub{
        a: 42,
        xxx: 42.42,
        z: -42
      },
      %Protox.Benchmarks.Sub{
        a: 42,
        z: -42
      },
      %Protox.Benchmarks.Sub{
        a: 3342,
        aaa: 666,
        bbb: "hey!",
        fff: 33.33000183105469,
        z: -10
      },
      %Protox.Benchmarks.Sub{
        a: 3342,
        b: "dqsqsdcqsqddqsqsd qsdqs dqsd ",
        c: -4_678_909_765,
        d: 29232,
        e: 8_938_293,
        f: -242_424,
        bbb: <<1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15>>,
        aaa: 666,
        fff: 33.33000183105469,
        z: -10,
        xxx: 42.31,
        zzz: "a string",
        r: :BAZ,
        o: [:BAZ, :FOO, :FOO, :FOO, :BAZ, :FOO, :BAZ, :FOO, :BAZ]
      },
      %Protox.Benchmarks.Sub{
        g: [0],
        h: [-1],
        i: [33.2, -44.0]
      },
      %Protox.Benchmarks.Sub{
        h: [-1, -2]
      },
      %Protox.Benchmarks.Msg{
        g: [
          3,
          270,
          86942,
          13,
          22,
          3423,
          23,
          132_432,
          12,
          98,
          142_442,
          14500,
          0,
          3,
          270,
          86942,
          13,
          22,
          3423,
          23,
          132_432,
          12,
          98,
          142_442,
          14500,
          0,
          3,
          270,
          86942,
          13,
          22,
          3423,
          23,
          132_432,
          12,
          98,
          142_442,
          14500,
          0,
          3,
          270,
          86942,
          13,
          22,
          3423,
          23,
          132_432,
          12,
          98,
          142_442,
          14500,
          0,
          3,
          270,
          86942,
          13,
          22,
          3423,
          23,
          132_432,
          12,
          98,
          142_442,
          14500,
          0,
          3,
          270,
          86942,
          13,
          22,
          3423,
          23,
          132_432,
          12,
          98,
          142_442,
          14500,
          0,
          3,
          270,
          86942,
          13,
          22,
          3423,
          23,
          132_432,
          12,
          98,
          142_442,
          14500,
          0,
          3
        ]
      },
      %Protox.Benchmarks.Msg{
        g: [1, 2, 3]
      },
      %Protox.Benchmarks.Msg{
        k: %{1 => "foo", 2 => "bar", 3 => "ddsq", 4 => "pjqsopjqs", 5 => "sdfqjz", 6 => "foqd"}
      },
      %Protox.Benchmarks.Msg{
        l: %{"bar" => 1.0, "foo" => 43.2, "baz" => 33.2, "fiz" => -3.4}
      },
      %Protox.Benchmarks.Upper{
        msg: %Protox.Benchmarks.Msg{
          f: %Protox.Benchmarks.Sub{
            a: 42,
            zzz: "efqpodiqfjqjpiosfqsfjopqfsopqsfopopqsfjpjoqcsojp"
          }
        }
      },
      %Protox.Benchmarks.Upper{
        empty: nil,
        map: %{
          "baz" => %Protox.Benchmarks.Msg{
            e: true
          },
          "foo" => %Protox.Benchmarks.Msg{
            d: :BAR
          }
        }
      },
      %Protox.Benchmarks.Sub{a: 150, b: "testing", c: 300, r: :BAR},
      %Protox.Benchmarks.Msg{
        d: :FOO,
        e: true,
        f: %Protox.Benchmarks.Sub{
          a: 150,
          b: "testing",
          c: 300,
          r: :BAR,
          g: [1, 2, 3, 4, 5, 6, 7, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20],
          n: [true, false, true, false, true, false]
        }
      },
      %Protox.Benchmarks.Msg{g: [1, 2, -3, 4, -5, 6, -7, 8, -9, 10]},
      %Protox.Benchmarks.Msg{
        j: [
          %Protox.Benchmarks.Sub{a: 42},
          %Protox.Benchmarks.Sub{b: "foo"},
          %Protox.Benchmarks.Sub{b: "foofoo"},
          %Protox.Benchmarks.Sub{b: "foobarfoobar"},
          %Protox.Benchmarks.Sub{b: "foobarbar"},
          %Protox.Benchmarks.Sub{b: "bartutfoo"},
          %Protox.Benchmarks.Sub{b: "bartutfoofiz"},
          %Protox.Benchmarks.Sub{b: "bartutfoo"}
        ]
      },
      %Protox.Benchmarks.Msg{
        l: %{
          "1" => 1.0,
          "2" => 2.0,
          "3" => 3.0,
          "4" => 4.0,
          "5" => 5.0,
          "6" => 6.0,
          "7" => 7.0,
          "8" => 8.0,
          "9" => 9.0,
          "10" => 10.0,
          "11" => 11.0,
          "12" => 12.0,
          "13" => 13.0,
          "14" => 14.0,
          "15" => 15.0,
          "16" => 16.0,
          "17" => 17.0,
          "18" => 18.0,
          "19" => 19.0,
          "20" => 20.0,
          "21" => 21.0,
          "22" => 22.0,
          "23" => 23.0,
          "24" => 24.0,
          "25" => 25.0,
          "26" => 26.0,
          "27" => 27.0,
          "28" => 28.0,
          "29" => 29.0,
          "30" => 30.0,
          "31" => 31.0,
          "32" => 32.0,
          "33" => 33.0,
          "34" => 34.0,
          "35" => 35.0,
          "36" => 36.0,
          "37" => 37.0,
          "38" => 38.0,
          "39" => 39.0,
          "40" => 40.0,
          "41" => 41.0,
          "42" => 42.0,
          "43" => 43.0,
          "44" => 44.0,
          "45" => 45.0,
          "46" => 46.0,
          "47" => 47.0,
          "48" => 48.0,
          "49" => 49.0,
          "50" => 50.0,
          "51" => 51.0,
          "52" => 52.0,
          "53" => 53.0,
          "54" => 54.0,
          "55" => 55.0,
          "56" => 56.0,
          "57" => 57.0,
          "58" => 58.0,
          "59" => 59.0,
          "60" => 60.0,
          "61" => 61.0,
          "62" => 62.0,
          "63" => 63.0,
          "64" => 64.0,
          "65" => 65.0,
          "66" => 66.0,
          "67" => 67.0,
          "68" => 68.0,
          "69" => 69.0,
          "70" => 70.0,
          "71" => 71.0,
          "72" => 72.0,
          "73" => 73.0,
          "74" => 74.0,
          "75" => 75.0,
          "76" => 76.0,
          "77" => 77.0,
          "78" => 78.0,
          "79" => 79.0,
          "80" => 80.0,
          "81" => 81.0,
          "82" => 82.0,
          "83" => 83.0,
          "84" => 84.0,
          "85" => 85.0,
          "86" => 86.0,
          "87" => 87.0,
          "88" => 88.0,
          "89" => 89.0,
          "90" => 90.0,
          "91" => 91.0,
          "92" => 92.0,
          "93" => 93.0,
          "94" => 94.0,
          "95" => 95.0,
          "96" => 96.0,
          "97" => 97.0,
          "98" => 98.0,
          "99" => 99.0,
          "100" => 100.0
        },
        m: {:n, "foo"}
      }
    ]
  end
end
