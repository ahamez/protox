defmodule Protox.NestedExtensionsTest do
  use ExUnit.Case

  use Protox,
    schema: """
      syntax = "proto2";

      message Extendee {
        extensions 100 to max;
      }

      message Extension1 {
        optional int32 a = 1;

        extend Extendee {
          optional Extension1 ext = 102;
        }
      }

      message Extension2 {
        extend Extendee {
          optional int32 ext = 103;
        }
      }

      message Extension3 {
        optional int32 a = 1;

        extend Extendee {
          repeated int32 ext = 104 [packed = true];
        }
      }

      # The binary encoding of the following message will the same
      # as the binary encoding of Extendee with its extension, as the fields
      # types and tags are the same.
      message ExtendeeWithExtensions {
        optional Extension1 extension1_ext = 102;
        optional int32 extension2_ext = 103;
        repeated int32 extension3_ext = 104 [packed = true];
      }

    """,
    namespace: Namespace

  alias Namespace.{
    Extendee,
    Extension1,
    Extension2,
    Extension3,
    ExtendeeWithExtensions
  }

  test "Extension1: message" do
    encoded =
      Protox.encode!(%ExtendeeWithExtensions{extension1_ext: %Extension1{a: 42}})
      |> :binary.list_to_bin()

    assert Extendee.decode!(encoded) == %Extendee{ext: {Extension1, %Extension1{a: 42}}}
  end

  test "Extension2: int32" do
    encoded = Protox.encode!(%ExtendeeWithExtensions{extension2_ext: -1}) |> :binary.list_to_bin()

    assert Extendee.decode!(encoded) == %Extendee{ext: {Extension2, -1}}
  end

  test "Extension3: repeated int32" do
    encoded =
      Protox.encode!(%ExtendeeWithExtensions{extension3_ext: [-1, 43, 12]})
      |> :binary.list_to_bin()

    assert Extendee.decode!(encoded) == %Extendee{ext: {Extension3, [-1, 43, 12]}}
  end

  test "Last set nested extension overrides previous one" do
    encoded_1 =
      Protox.encode!(%ExtendeeWithExtensions{extension2_ext: -1})
      |> :binary.list_to_bin()

    encoded_2 =
      Protox.encode!(%ExtendeeWithExtensions{extension3_ext: [-1, 43, 12]})
      |> :binary.list_to_bin()

    encoded = encoded_1 <> encoded_2
    assert Extendee.decode!(encoded) == %Extendee{ext: {Extension3, [-1, 43, 12]}}

    # Reverse order
    encoded = encoded_2 <> encoded_1
    assert Extendee.decode!(encoded) == %Extendee{ext: {Extension2, -1}}
  end
end
