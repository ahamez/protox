defmodule Protox.Message do
  @moduledoc """
  This module provides a helper function to merge messages.
  """

  alias Protox.Field

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
      iex> r1 = %Protobuf2{a: 0, s: :ONE}
      iex> r2 = %Protobuf2{a: nil, s: :TWO}
      iex> Protox.Message.merge(r1, r2)
      %Protobuf2{a: 0, s: :TWO}
      iex> Protox.Message.merge(r2, r1)
      %Protobuf2{a: 0, s: :ONE}
  """
  @spec merge(struct | nil, struct | nil) :: struct | nil
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
    case msg.__struct__.field_def(name) do
      {:ok, %Field{kind: :packed}} ->
        v1 ++ v2

      {:ok, %Field{kind: :unpacked}} ->
        v1 ++ v2

      {:ok, %Field{kind: {:scalar, _}, type: {:message, _}}} ->
        merge(v1, v2)

      {:ok, %Field{kind: {:scalar, _}}} ->
        {:ok, default} = msg.__struct__.default(name)
        merge_scalar(msg.__struct__.syntax(), v1, v2, default)

      {:ok, %Field{kind: :map, type: {_, {:message, _}}}} ->
        Map.merge(v1, v2, fn _key, w1, w2 -> merge(w1, w2) end)

      {:ok, %Field{kind: :map}} ->
        Map.merge(v1, v2)

      {:error, :no_such_field} ->
        merge_oneof(msg, v1, v2)
    end
  end

  defp merge_scalar(:proto2, v1, nil, _default), do: v1
  defp merge_scalar(:proto3, v1, v2, default) when v2 == default, do: v1
  defp merge_scalar(_syntax, _v1, v2, _default), do: v2

  defp merge_oneof(
         msg,
         {v1_child_field, v1_child_value},
         {v2_child_field, v2_child_value} = v2
       )
       when v1_child_field == v2_child_field do
    {:ok, v1_child_field_def} = msg.__struct__.field_def(v1_child_field)
    {:ok, v2_child_field_def} = msg.__struct__.field_def(v2_child_field)

    if is_oneof_message(v1_child_field_def) and is_oneof_message(v2_child_field_def) do
      {v1_child_field, merge(v1_child_value, v2_child_value)}
    else
      v2
    end
  end

  defp merge_oneof(_msg, v1, nil), do: v1
  defp merge_oneof(_msg, _v1, v2), do: v2

  defp is_oneof_message(%Field{kind: {:oneof, _}, type: {:message, _}}), do: true
  defp is_oneof_message(_), do: false
end
