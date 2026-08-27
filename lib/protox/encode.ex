defmodule Protox.Encode do
  @moduledoc false

  use Protox.{
    Float,
    WireTypes
  }

  import Bitwise
  import Protox.Guards

  alias Protox.{
    Varint,
    Zigzag
  }

  @doc false
  @spec make_key_bytes(Protox.Types.tag(), Protox.Types.type()) :: {binary(), non_neg_integer()}
  def make_key_bytes(tag, ty) do
    Varint.encode(make_key(tag, ty))
  end

  @doc false
  @spec make_key(Protox.Types.tag(), Protox.Types.type()) :: non_neg_integer()
  def make_key(tag, ty) when is_primitive_varint(ty), do: tag <<< 3 ||| @wire_varint
  def make_key(tag, {:enum, _mod}), do: tag <<< 3 ||| @wire_varint
  def make_key(tag, ty) when is_primitive_fixed64(ty), do: tag <<< 3 ||| @wire_64bits
  def make_key(tag, ty) when is_delimited(ty), do: tag <<< 3 ||| @wire_delimited
  def make_key(tag, {:message, _mod}), do: tag <<< 3 ||| @wire_delimited
  def make_key(tag, :packed), do: tag <<< 3 ||| @wire_delimited
  def make_key(tag, :map_entry), do: tag <<< 3 ||| @wire_delimited
  def make_key(tag, ty) when is_primitive_fixed32(ty), do: tag <<< 3 ||| @wire_32bits

  @doc false
  @spec encode_bool(boolean()) :: {binary(), non_neg_integer()}
  def encode_bool(false), do: {<<0>>, 1}
  def encode_bool(true), do: {<<1>>, 1}

  @doc false
  @spec encode_string(String.t()) :: {iodata(), non_neg_integer()}
  def encode_string(value) do
    case Protox.String.validate(value) do
      :ok ->
        {size_varint, size} = Varint.encode(byte_size(value))
        {[size_varint, value], size + byte_size(value)}

      {:error, :invalid_utf8} ->
        raise ArgumentError, message: "String is not valid UTF-8"

      {:error, :too_large} ->
        raise ArgumentError, message: "String is too large"
    end
  end

  @doc false
  @spec encode_bytes(binary()) :: {iodata(), non_neg_integer()}
  def encode_bytes(value) do
    {size_varint, size} = Varint.encode(byte_size(value))
    {[size_varint, value], size + byte_size(value)}
  end

  # Packed elements are appended to a single contiguous binary: amortized O(1)
  # binary append, one reduction per element, and the packed length comes for
  # free from byte_size/1.

  @doc false
  @spec encode_packed_int32([integer()], binary()) :: binary()
  def encode_packed_int32([], acc), do: acc

  def encode_packed_int32([value | rest], acc) do
    encode_packed_int32(rest, append_int32(acc, value))
  end

  @doc false
  @spec encode_packed_int64([integer()], binary()) :: binary()
  def encode_packed_int64([], acc), do: acc

  def encode_packed_int64([value | rest], acc) do
    encode_packed_int64(rest, Varint.append(acc, value &&& 0xFFFF_FFFF_FFFF_FFFF))
  end

  @doc false
  # Zigzag encoding is width-agnostic: sint32 and sint64 share this appender.
  @spec encode_packed_sint([integer()], binary()) :: binary()
  def encode_packed_sint([], acc), do: acc

  def encode_packed_sint([value | rest], acc) do
    encode_packed_sint(rest, Varint.append(acc, Zigzag.encode(value)))
  end

  @doc false
  @spec encode_packed_bool([boolean()], binary()) :: binary()
  def encode_packed_bool([], acc), do: acc
  def encode_packed_bool([true | rest], acc), do: encode_packed_bool(rest, <<acc::binary, 1>>)
  def encode_packed_bool([false | rest], acc), do: encode_packed_bool(rest, <<acc::binary, 0>>)

  @doc false
  @spec encode_packed_enum([atom() | integer()], binary(), (atom() | integer() -> integer())) :: binary()
  def encode_packed_enum([], acc, _encode_enum_fun), do: acc

  def encode_packed_enum([value | rest], acc, encode_enum_fun) do
    encode_packed_enum(rest, append_int32(acc, encode_enum_fun.(value)), encode_enum_fun)
  end

  defp append_int32(acc, value) when is_integer(value) and value >= 0 do
    Varint.append(acc, value &&& 0xFFFF_FFFF)
  end

  defp append_int32(acc, value) when is_integer(value) do
    Varint.append(acc, value &&& 0xFFFF_FFFF_FFFF_FFFF)
  end

  # Packed fixed-width elements are appended to a single contiguous binary:
  # amortized O(1) binary append, one reduction per element, and the packed
  # length comes for free from byte_size/1.

  @doc false
  # The signed modifier is a no-op in binary construction: sfixed32/64 share
  # the fixed32/64 appenders.
  @spec encode_packed_fixed32([integer()], binary()) :: binary()
  def encode_packed_fixed32([], acc), do: acc

  def encode_packed_fixed32([value | rest], acc) do
    encode_packed_fixed32(rest, <<acc::binary, value::little-32>>)
  end

  @doc false
  @spec encode_packed_fixed64([integer()], binary()) :: binary()
  def encode_packed_fixed64([], acc), do: acc

  def encode_packed_fixed64([value | rest], acc) do
    encode_packed_fixed64(rest, <<acc::binary, value::little-64>>)
  end

  @doc false
  @spec encode_packed_float([float() | atom()], binary()) :: binary()
  def encode_packed_float([], acc), do: acc

  def encode_packed_float([:infinity | rest], acc) do
    encode_packed_float(rest, <<acc::binary, @positive_infinity_32::binary>>)
  end

  def encode_packed_float([:"-infinity" | rest], acc) do
    encode_packed_float(rest, <<acc::binary, @negative_infinity_32::binary>>)
  end

  def encode_packed_float([:nan | rest], acc) do
    encode_packed_float(rest, <<acc::binary, @nan_32::binary>>)
  end

  def encode_packed_float([value | rest], acc) do
    encode_packed_float(rest, <<acc::binary, value::float-little-32>>)
  end

  @doc false
  @spec encode_packed_double([float() | atom()], binary()) :: binary()
  def encode_packed_double([], acc), do: acc

  def encode_packed_double([:infinity | rest], acc) do
    encode_packed_double(rest, <<acc::binary, @positive_infinity_64::binary>>)
  end

  def encode_packed_double([:"-infinity" | rest], acc) do
    encode_packed_double(rest, <<acc::binary, @negative_infinity_64::binary>>)
  end

  def encode_packed_double([:nan | rest], acc) do
    encode_packed_double(rest, <<acc::binary, @nan_64::binary>>)
  end

  def encode_packed_double([value | rest], acc) do
    encode_packed_double(rest, <<acc::binary, value::float-little-64>>)
  end

  @doc false
  # Cold path: runs each field encoder in isolation and raises an EncodingError
  # naming the first field whose encoder fails. Already-attributed errors pass
  # through untouched.
  @spec find_invalid_field!([{atom(), (-> any())}]) :: :ok | no_return()
  def find_invalid_field!(entries) do
    Enum.each(entries, fn {name, encode_fun} ->
      try do
        encode_fun.()
      rescue
        e in [Protox.EncodingError, Protox.RequiredFieldsError] ->
          reraise e, __STACKTRACE__

        _e ->
          reraise Protox.EncodingError.new(name, "invalid field value"), __STACKTRACE__
      end
    end)
  end

  @doc false
  # Cold path: recursively encodes message children of the expected module
  # through their own (rescued) encode!/1 so an EncodingError is attributed to
  # the innermost faulty field. Values of any other shape (including structs of
  # the wrong type) are left to the field encoder replay, which reports the
  # error under the parent field's name.
  @spec diagnose_children!(any(), module()) :: any()
  def diagnose_children!(%mod{} = child, mod), do: mod.encode!(child)

  def diagnose_children!(children, mod) when is_list(children) do
    Enum.each(children, &diagnose_children!(&1, mod))
  end

  def diagnose_children!(children, mod) when is_map(children) and not is_struct(children) do
    Enum.each(children, fn {_key, value} -> diagnose_children!(value, mod) end)
  end

  def diagnose_children!(_other, _mod), do: :ok
end
