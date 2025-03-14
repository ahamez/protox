defmodule OptionalProto3Test do
  use ExUnit.Case

  test "A proto3 optional field is encoded as a oneof" do
    msg1 = %OptionalMsg1{foo: 1}
    msg2 = %OptionalMsg2{_foo: {:foo, 1}}

    encoded_msg1 = msg1 |> OptionalMsg1.encode!() |> elem(0) |> IO.iodata_to_binary()
    encoded_msg2 = msg2 |> OptionalMsg2.encode!() |> elem(0) |> IO.iodata_to_binary()

    assert encoded_msg1 == encoded_msg2

    decoded_msg2_as_msg1 = encoded_msg2 |> OptionalMsg1.decode!()
    assert decoded_msg2_as_msg1 == msg1
  end

  test "A unset proto3 optional field is not serialized" do
    explicit_nil = %OptionalMsg1{foo: nil}
    implicit_nil = %OptionalMsg1{}

    assert explicit_nil |> OptionalMsg1.encode!() |> elem(0) |> IO.iodata_to_binary() == <<>>
    assert implicit_nil |> OptionalMsg1.encode!() |> elem(0) |> IO.iodata_to_binary() == <<>>
  end

  test "A proto3 optional empty message field is encoded as a oneof" do
    msg3 = %OptionalMsg3{foo: %OptionalMsg1{}}
    msg4 = %OptionalMsg4{_foo: {:foo, %OptionalMsg1{}}}

    encoded_msg3 = msg3 |> OptionalMsg3.encode!() |> elem(0) |> IO.iodata_to_binary()
    encoded_msg4 = msg4 |> OptionalMsg4.encode!() |> elem(0) |> IO.iodata_to_binary()

    assert encoded_msg3 == encoded_msg4

    decoded_msg4_as_msg3 = encoded_msg4 |> OptionalMsg3.decode!()
    assert decoded_msg4_as_msg3 == msg3
  end

  test "A proto3 optional non-empty message field is encoded as a oneof" do
    msg3 = %OptionalMsg3{foo: %OptionalMsg1{foo: -42}}
    msg4 = %OptionalMsg4{_foo: {:foo, %OptionalMsg1{foo: -42}}}

    encoded_msg3 = msg3 |> OptionalMsg3.encode!() |> elem(0) |> IO.iodata_to_binary()
    encoded_msg4 = msg4 |> OptionalMsg4.encode!() |> elem(0) |> IO.iodata_to_binary()

    assert encoded_msg3 == encoded_msg4

    decoded_msg4_as_msg3 = encoded_msg4 |> OptionalMsg3.decode!()
    assert decoded_msg4_as_msg3 == msg3
  end

  test "A unset proto3 optional message field is not serialized" do
    explicit_nil = %OptionalMsg3{foo: nil}
    implicit_nil = %OptionalMsg3{}

    assert explicit_nil |> OptionalMsg3.encode!() |> elem(0) |> IO.iodata_to_binary() == <<>>
    assert implicit_nil |> OptionalMsg3.encode!() |> elem(0) |> IO.iodata_to_binary() == <<>>
  end

  test "Use the latest set value on the wire" do
    bin1 = <<10, 2, 8, 32>>
    bin2 = <<10, 2, 8, 100>>

    assert (bin1 <> bin2) |> OptionalMsg3.decode!() == %OptionalMsg3{foo: %OptionalMsg1{foo: 100}}
    assert (bin2 <> bin1) |> OptionalMsg3.decode!() == %OptionalMsg3{foo: %OptionalMsg1{foo: 32}}
  end
end
