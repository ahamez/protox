defmodule OptionalProto3Test do
  use ExUnit.Case

  test "A proto3 optional field is encoded as a oneof" do
    msg1 = %Msg1{foo: 1}
    msg2 = %Msg2{_foo: {:foo, 1}}

    encoded_msg1 = msg1 |> Msg1.encode!() |> :binary.list_to_bin()
    encoded_msg2 = msg2 |> Msg2.encode!() |> :binary.list_to_bin()

    assert encoded_msg1 == encoded_msg2
  end

  test "A proto3 synthetic oneof can be decoded as an optional field" do
    msg1 = %Msg1{foo: 1}
    msg2 = %Msg2{_foo: {:foo, 1}}

    assert msg2 |> Msg2.encode!() |> :binary.list_to_bin() |> Msg1.decode!() == msg1
  end

  test "A unset proto3 optional field is not serialized" do
    explicit_nil = %Msg1{foo: nil}
    implicit_nil = %Msg1{}

    assert explicit_nil |> Msg1.encode!() |> :binary.list_to_bin() == <<>>
    assert implicit_nil |> Msg1.encode!() |> :binary.list_to_bin() == <<>>
  end

  test "A proto3 optional empty message field is encoded as a oneof" do
    msg3 = %Msg3{foo: %Msg1{}}
    msg4 = %Msg4{_foo: {:foo, %Msg1{}}}

    encoded_msg3 = msg3 |> Msg3.encode!() |> :binary.list_to_bin()
    encoded_msg4 = msg4 |> Msg4.encode!() |> :binary.list_to_bin()

    assert encoded_msg3 == encoded_msg4
  end

  test "A proto3 optional non-empty message field is encoded as a oneof" do
    msg3 = %Msg3{foo: %Msg1{foo: -42}}
    msg4 = %Msg4{_foo: {:foo, %Msg1{foo: -42}}}

    encoded_msg3 = msg3 |> Msg3.encode!() |> :binary.list_to_bin()
    encoded_msg4 = msg4 |> Msg4.encode!() |> :binary.list_to_bin()

    assert encoded_msg3 == encoded_msg4
  end

  test "A unset proto3 optional message field is not serialized" do
    explicit_nil = %Msg3{foo: nil}
    implicit_nil = %Msg3{}

    assert explicit_nil |> Msg3.encode!() |> :binary.list_to_bin() == <<>>
    assert implicit_nil |> Msg3.encode!() |> :binary.list_to_bin() == <<>>
  end
end
