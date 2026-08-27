defmodule Protox.EncodeErrorAttributionTest do
  use ExUnit.Case, async: true

  alias ProtobufTestMessages.Proto3.{ForeignMessage, TestAllTypesProto3}

  describe "error attribution" do
    test "an invalid scalar field raises EncodingError naming the field" do
      msg = %TestAllTypesProto3{optional_int32: :not_an_int}

      assert_raise Protox.EncodingError, ~r/Could not encode field :optional_int32 /, fn ->
        TestAllTypesProto3.encode!(msg)
      end
    end

    test "an invalid field in a nested message is attributed to the nested field" do
      nested = %TestAllTypesProto3.NestedMessage{a: :not_an_int}
      msg = %TestAllTypesProto3{optional_nested_message: nested}

      assert_raise Protox.EncodingError, ~r/Could not encode field :a /, fn ->
        TestAllTypesProto3.encode!(msg)
      end
    end

    test "an invalid repeated field raises EncodingError naming the field" do
      msg = %TestAllTypesProto3{repeated_int32: [1, :not_an_int]}

      assert_raise Protox.EncodingError, ~r/Could not encode field :repeated_int32 /, fn ->
        TestAllTypesProto3.encode!(msg)
      end
    end

    test "an invalid map value raises EncodingError naming the field" do
      msg = %TestAllTypesProto3{map_int32_int32: %{1 => :not_an_int}}

      assert_raise Protox.EncodingError, ~r/Could not encode field :map_int32_int32 /, fn ->
        TestAllTypesProto3.encode!(msg)
      end
    end

    test "an invalid field in a message-typed oneof child is attributed to the nested field" do
      nested = %TestAllTypesProto3.NestedMessage{a: :not_an_int}
      msg = %TestAllTypesProto3{oneof_field: {:oneof_nested_message, nested}}

      assert_raise Protox.EncodingError, ~r/Could not encode field :a /, fn ->
        TestAllTypesProto3.encode!(msg)
      end
    end

    test "an invalid scalar oneof inside a nested message is attributed to the outer field" do
      nested = %TestAllTypesProto3{oneof_field: {:oneof_uint32, :not_an_int}}
      msg = %TestAllTypesProto3{recursive_message: nested}

      assert_raise Protox.EncodingError, ~r/Could not encode field :recursive_message /, fn ->
        TestAllTypesProto3.encode!(msg)
      end
    end

    test "a non-protox struct in a scalar field is attributed to that field" do
      msg = %TestAllTypesProto3{optional_string: %URI{}}

      assert_raise Protox.EncodingError, ~r/Could not encode field :optional_string /, fn ->
        TestAllTypesProto3.encode!(msg)
      end
    end

    test "a struct of the wrong type in a message field is attributed to that field" do
      msg = %TestAllTypesProto3{
        optional_nested_message: %ForeignMessage{}
      }

      assert_raise Protox.EncodingError, ~r/Could not encode field :optional_nested_message /, fn ->
        TestAllTypesProto3.encode!(msg)
      end
    end

    test "a wrong-type struct with its own invalid fields is still attributed to the parent field" do
      msg = %TestAllTypesProto3{
        optional_nested_message: %ForeignMessage{c: :not_an_int}
      }

      assert_raise Protox.EncodingError, ~r/Could not encode field :optional_nested_message /, fn ->
        TestAllTypesProto3.encode!(msg)
      end
    end

    test "a struct of the wrong type in a message oneof is attributed to the oneof" do
      msg = %TestAllTypesProto3{oneof_field: {:oneof_nested_message, %ForeignMessage{}}}

      assert_raise Protox.EncodingError, ~r/Could not encode field :oneof_field /, fn ->
        TestAllTypesProto3.encode!(msg)
      end

      assert {:error, %Protox.EncodingError{field: :oneof_field}} =
               TestAllTypesProto3.encode(msg)
    end

    test "an invalid bool field raises EncodingError naming the field" do
      msg = %TestAllTypesProto3{optional_bool: 1}

      assert_raise Protox.EncodingError, ~r/Could not encode field :optional_bool /, fn ->
        TestAllTypesProto3.encode!(msg)
      end
    end

    test "a plain map in a message field is attributed to that field" do
      msg = %TestAllTypesProto3{optional_nested_message: %{a: 42}}

      assert_raise Protox.EncodingError, ~r/Could not encode field :optional_nested_message /, fn ->
        TestAllTypesProto3.encode!(msg)
      end
    end

    test "a malformed top-level input reraises the original error" do
      # No field can be blamed when the input is not the expected struct.
      assert_raise KeyError, fn ->
        TestAllTypesProto3.encode!(%{})
      end

      assert_raise KeyError, fn ->
        ForeignMessage.encode!(%{})
      end
    end

    test "an invalid scalar oneof takes precedence over a later invalid field" do
      # Oneofs are encoded first: when several fields are invalid, the
      # diagnosis must report the error of the field that failed first.
      msg = %TestAllTypesProto3{
        oneof_field: {:oneof_uint32, :not_an_int},
        optional_int32: :also_not_an_int
      }

      assert_raise ArithmeticError, fn ->
        TestAllTypesProto3.encode!(msg)
      end
    end

    test "an invalid oneof child keeps raising a raw error" do
      # Oneof children have never been wrapped into EncodingError; pin this
      # behavior so the encoder restructuring doesn't silently change it.
      # The raw error type depends on the child's type.
      varint_msg = %TestAllTypesProto3{oneof_field: {:oneof_uint32, :not_an_int}}

      assert_raise ArithmeticError, fn ->
        TestAllTypesProto3.encode!(varint_msg)
      end

      string_msg = %TestAllTypesProto3{oneof_field: {:oneof_string, 42}}

      assert_raise ArgumentError, fn ->
        TestAllTypesProto3.encode!(string_msg)
      end
    end
  end
end
