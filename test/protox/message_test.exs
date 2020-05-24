defmodule Protox.MessageTest do
  use ExUnit.Case

  test "Protobuf 2, replace only set scalar fields" do
    r1 = %Protobuf2{a: 0, s: :ONE}
    r2 = %Protobuf2{a: nil, s: :TWO}
    r3 = %Protobuf2{a: 1, s: nil}

    assert Protox.Message.merge(r1, r2) == %Protobuf2{a: 0, s: :TWO}
    assert Protox.Message.merge(r1, r3) == %Protobuf2{a: 1, s: :ONE}
    assert Protox.Message.merge(r2, r1) == %Protobuf2{a: 0, s: :ONE}
    assert Protox.Message.merge(r3, r1) == %Protobuf2{a: 0, s: :ONE}
  end

  test "Replace scalar fields" do
    r1 = %Required{a: 3, b: 4}
    r2 = %Required{a: 5, b: 7}

    assert Protox.Message.merge(r1, r2) == %Required{a: 5, b: 7}
    assert Protox.Message.merge(r2, r1) == %Required{a: 3, b: 4}
  end

  test "Concatenate repeated fields" do
    m1 = %Sub{g: [], j: [4, 5, 6]}
    m2 = %Sub{g: [10, 20], j: [1, 2, 3]}

    assert Protox.Message.merge(m1, m2) == %Sub{g: [10, 20], j: [4, 5, 6, 1, 2, 3]}
    assert Protox.Message.merge(m2, m1) == %Sub{g: [10, 20], j: [1, 2, 3, 4, 5, 6]}
  end

  test "Recursively merge messages" do
    m1 = %Msg{msg_e: true, msg_f: %Sub{g: [], j: [4, 5, 6]}}
    m2 = %Msg{msg_e: false, msg_f: %Sub{g: [10, 20], j: [1, 2, 3]}}

    assert Protox.Message.merge(m1, m2) == %Msg{
             msg_e: true,
             msg_f: %Sub{g: [10, 20], j: [4, 5, 6, 1, 2, 3]}
           }

    assert Protox.Message.merge(m2, m1) == %Msg{
             msg_e: true,
             msg_f: %Sub{g: [10, 20], j: [1, 2, 3, 4, 5, 6]}
           }
  end

  test "Overwrite nil messages" do
    m1 = %Msg{msg_f: nil}
    m2 = %Msg{msg_f: %Sub{g: [10, 20], j: [1, 2, 3]}}

    assert Protox.Message.merge(m1, m2) == %Msg{
             msg_f: %Sub{g: [10, 20], j: [1, 2, 3]}
           }

    assert Protox.Message.merge(m2, m1) == %Msg{
             msg_f: nil
           }
  end

  test "Recursively merge messages in oneof" do
    m1 = %Msg{msg_m: {:msg_o, %Sub{k: 2, j: [4, 5, 6]}}}
    m2 = %Msg{msg_m: {:msg_o, %Sub{k: 3, j: [1, 2, 3]}}}

    assert Protox.Message.merge(m1, m2) == %Msg{
             msg_m: {:msg_o, %Sub{k: 3, j: [4, 5, 6, 1, 2, 3]}}
           }

    assert Protox.Message.merge(m2, m1) == %Msg{
             msg_m: {:msg_o, %Sub{k: 2, j: [1, 2, 3, 4, 5, 6]}}
           }
  end

  test "Overwrite non-messages oneof" do
    m1 = %Msg{msg_m: {:msg_n, :FOO}}
    m2 = %Msg{msg_m: {:msg_n, :BAR}}

    assert Protox.Message.merge(m1, m2) == %Msg{
             msg_m: {:msg_n, :BAR}
           }

    assert Protox.Message.merge(m2, m1) == %Msg{
             msg_m: {:msg_n, :FOO}
           }
  end

  test "Merge scalar maps" do
    m1 = %Msg{msg_k: %{1 => "a", 2 => "b", 100 => "c"}}
    m2 = %Msg{msg_k: %{1 => "x", 2 => "y", 101 => "z"}}

    assert Protox.Message.merge(m1, m2) == %Msg{
             msg_k: %{1 => "x", 2 => "y", 100 => "c", 101 => "z"}
           }

    assert Protox.Message.merge(m2, m1) == %Msg{
             msg_k: %{1 => "a", 2 => "b", 100 => "c", 101 => "z"}
           }
  end

  test "Merge messages maps" do
    m1 = %Upper{
      msg_map: %{
        "1" => %Msg{msg_e: true, msg_f: %Sub{g: [], j: [4, 5, 6]}},
        "2" => %Msg{msg_d: :FOO, msg_m: {:msg_n, "FOO"}},
        "100" => %Msg{msg_a: 33}
      }
    }

    m2 = %Upper{
      msg_map: %{
        "1" => %Msg{msg_e: false, msg_f: %Sub{g: [10, 20], j: [1, 2, 3]}},
        "2" => %Msg{msg_d: :BAR, msg_m: {:msg_o, %Sub{}}},
        "101" => %Msg{msg_a: 44}
      }
    }

    assert Protox.Message.merge(m1, m2) == %Upper{
             msg_map: %{
               "1" => %Msg{msg_e: true, msg_f: %Sub{g: [10, 20], j: [4, 5, 6, 1, 2, 3]}},
               "2" => %Msg{msg_d: :BAR, msg_m: {:msg_o, %Sub{}}},
               "100" => %Msg{msg_a: 33},
               "101" => %Msg{msg_a: 44}
             }
           }

    assert Protox.Message.merge(m2, m1) == %Upper{
             msg_map: %{
               "1" => %Msg{msg_e: true, msg_f: %Sub{g: [10, 20], j: [1, 2, 3, 4, 5, 6]}},
               "2" => %Msg{msg_d: :BAR, msg_m: {:msg_n, "FOO"}},
               "100" => %Msg{msg_a: 33},
               "101" => %Msg{msg_a: 44}
             }
           }
  end
end
