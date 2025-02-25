defmodule Protox.MergeMessage do
  @moduledoc """
  This module provides a helper function to merge messages.
  """

  alias Protox.{Field, OneOf, Scalar}

  @doc """
  Singular fields of `msg` will be overwritten, if specified in `from`, except for
  embedded messages which will be merged. Repeated fields will be concatenated.

  Note that "specified" has a different meaning in protobuf 2 and 3:
  - 2: if the singular field from `from` is nil, the value from `msg` is kept
  - 3: if the singular field from `from` is set to the default value, the value from `msg` is
  kept. This behaviour matches the C++ reference implementation behaviour.

  - `msg` and `from` must be of the same type; or
  - either `msg` or `from` is `nil`: the non-nil message is returned; or
  - both are `nil`: `nil` is returned

  # Example
      iex> r1 = %Protobuf2Message{a: 0, b: :ONE}
      iex> r2 = %Protobuf2Message{a: nil, b: :TWO}
      iex> Protox.MergeMessage.merge(r1, r2)
      %Protobuf2Message{a: 0, b: :TWO}
      iex> Protox.MergeMessage.merge(r2, r1)
      %Protobuf2Message{a: 0, b: :ONE}
  """
  @spec merge(struct() | nil, struct() | nil) :: struct() | nil
  def merge(nil, from), do: from
  def merge(msg, nil), do: msg

  def merge(msg, from) do
    unknown_fields_name = msg.__struct__.unknown_fields_name()

    Map.merge(msg, from, fn
      :__struct__, v1, _v2 ->
        v1

      ^unknown_fields_name, v1, _v2 ->
        v1

      name, v1, v2 ->
        merge_field(msg, name, v1, v2)
    end)
  end

  # -- Private

  defp merge_field(msg, name, v1, v2) do
    case Map.get(msg.__struct__.schema().fields, name) do
      %Field{kind: :packed} ->
        v1 ++ v2

      %Field{kind: :unpacked} ->
        v1 ++ v2

      %Field{kind: %Scalar{}, type: {:message, _}} ->
        merge(v1, v2)

      %Field{kind: %Scalar{}} ->
        {:ok, default} = msg.__struct__.default(name)
        merge_scalar(msg.__struct__.schema().syntax, v1, v2, default)

      %Field{kind: :map, type: {_, {:message, _}}} ->
        Map.merge(v1, v2, fn _key, w1, w2 -> merge(w1, w2) end)

      %Field{kind: :map} ->
        Map.merge(v1, v2)

      nil ->
        merge_oneof(msg, v1, v2)
    end
  end

  defp merge_scalar(:proto2, v1, nil, _default), do: v1
  defp merge_scalar(:proto3, v1, v2, v2), do: v1
  defp merge_scalar(_syntax, _v1, v2, _default), do: v2

  defp merge_oneof(msg, {v1_child_field, v1_child_value}, {v2_child_field, v2_child_value} = v2)
       when v1_child_field == v2_child_field do
    v1_child_field_def = Map.fetch!(msg.__struct__.schema().fields, v1_child_field)
    v2_child_field_def = Map.fetch!(msg.__struct__.schema().fields, v2_child_field)

    if oneof_message?(v1_child_field_def) and oneof_message?(v2_child_field_def) do
      {v1_child_field, merge(v1_child_value, v2_child_value)}
    else
      v2
    end
  end

  defp merge_oneof(_msg, v1, nil), do: v1
  defp merge_oneof(_msg, _v1, v2), do: v2

  defp oneof_message?(%Field{kind: %OneOf{}, type: {:message, _}}), do: true
  defp oneof_message?(_), do: false
end
