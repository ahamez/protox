defmodule Protox.NestedExtensionsTest do
  use ExUnit.Case, async: true

  test "Extension1: message" do
    encoded_reference =
      %ExtendeeWithInlinedExtensions{extension1_ext: %Extension1{a: 42}}
      |> Protox.encode!()
      |> elem(0)
      |> :binary.list_to_bin()

    extendee = %Extendee{extension1_ext1: %Extension1{a: 42}}

    assert Extendee.decode!(encoded_reference) == extendee

    assert extendee
           |> Extendee.encode!()
           |> elem(0)
           |> :binary.list_to_bin() == encoded_reference
  end

  test "Extension2: int32" do
    encoded_reference =
      %ExtendeeWithInlinedExtensions{extension2_ext: -1}
      |> Protox.encode!()
      |> elem(0)
      |> :binary.list_to_bin()

    extendee = %Extendee{extension2_ext2: -1}

    assert Extendee.decode!(encoded_reference) == extendee

    assert extendee
           |> Extendee.encode!()
           |> elem(0)
           |> :binary.list_to_bin() == encoded_reference
  end

  test "Extension3: repeated int32" do
    encoded_reference =
      %ExtendeeWithInlinedExtensions{extension3_ext: [-1, 43, 12]}
      |> Protox.encode!()
      |> elem(0)
      |> :binary.list_to_bin()

    extendee = %Extendee{extension3_ext3: [-1, 43, 12]}

    assert Extendee.decode!(encoded_reference) == extendee

    assert extendee
           |> Extendee.encode!()
           |> elem(0)
           |> :binary.list_to_bin() == encoded_reference
  end

  test "Duplicate field names in different extensions: both fields are kept" do
    encoded_reference_4 =
      %ExtendeeWithInlinedExtensions{extension4_ext: -1}
      |> Protox.encode!()
      |> elem(0)
      |> :binary.list_to_bin()

    encoded_reference_5 =
      %ExtendeeWithInlinedExtensions{extension5_ext: [-1, 43, 12]}
      |> Protox.encode!()
      |> elem(0)
      |> :binary.list_to_bin()

    encoded_reference_4_5 = encoded_reference_4 <> encoded_reference_5
    extendee = %Extendee{extension4_ext: -1, extension5_ext: [-1, 43, 12]}
    assert Extendee.decode!(encoded_reference_4_5) == extendee
    # Reverse order
    encoded_reference = encoded_reference_5 <> encoded_reference_4
    assert Extendee.decode!(encoded_reference) == extendee

    assert extendee
           |> Extendee.encode!()
           |> elem(0)
           |> :binary.list_to_bin() == encoded_reference_4_5
  end
end
