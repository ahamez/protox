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
        g: [3, 270, 86942, 13, 22, 3423, 23, 132_432, 12, 98, 142_442, 14500, 0, 3]
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
        j: [%Protox.Benchmarks.Sub{a: 42}, %Protox.Benchmarks.Sub{b: "foo"}]
      },
      %Protox.Benchmarks.Msg{
        l: %{"1" => 1.0, "2" => 2.0, "3" => 3.0, "4" => 4.0},
        m: {:n, "foo"}
      }
    ]
  end
end
