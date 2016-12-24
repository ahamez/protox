defmodule ProtoxTest do
  use ExUnit.Case

  test "symmetric (Sub)" do
    msg = Protox.RandomInit.gen(Sub)
    assert (msg |> Sub.encode_binary() |> Sub.decode!()) == msg
  end


  test "symmetric (Msg)" do
    msg = Protox.RandomInit.gen(Msg)
    assert (msg |> Msg.encode_binary() |> Msg.decode!()) == msg
  end


  test "symmetric (Upper)" do
    msg = Protox.RandomInit.gen(Upper)
    assert (msg |> Upper.encode_binary() |> Upper.decode!()) == msg
  end

end
