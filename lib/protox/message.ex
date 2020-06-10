defmodule Protox.Message do
  @moduledoc """
  This module provides functions to work with messages.
  """

  @doc """
  Singular fields of `msg` will be overwritten, if specified in `from`, except for
  embedded messages which will be merged. Repeated fields will be concatenated.

  Note that "specified" has a different meaning in protobuf 2 and 3:
  - 2: if the singular field from `from` is nil, the value from `msg` is kept
  - 3: if the singular field from `from` is set to the default value, the value from `msg` is kept
  This behaviour matches the C++ reference implementation behaviour.

  - `msg` and `from` must be of the same type; or
  - either `msg` or `from` is `nil`: the non-nil message is returned; or
  - both are `nil`: `nil` is returned
  """
  @spec merge(struct | nil, struct | nil) :: struct | nil
  def merge(nil, from), do: from
  def merge(msg, nil), do: msg

  def merge(msg, from) do
    Map.merge(msg, from, fn name, v1, v2 ->
      if name == :__struct__ or name == msg.__struct__.unknown_fields_name() do
        v1
      else
        merge_field(msg, name, v1, v2)
      end
    end)
  end

  defp merge_field(msg, name, v1, v2) do
    defs = msg.__struct__.defs_by_name()
    syntax = msg.__struct__.syntax()

    case defs[name] do
      {_, :packed, _} ->
        v1 ++ v2

      {_, :unpacked, _} ->
        v1 ++ v2

      {_, {:default, _}, {:message, _}} ->
        merge_message(v1, v2)

      {_, {:default, _}, _} ->
        {:ok, default} = msg.__struct__.default(name)
        merge_scalar(syntax, v1, v2, default)

      nil ->
        merge_oneof(v1, v2, defs)

      {_, :map, {_, {:message, _}}} ->
        Map.merge(v1, v2, fn _k, w1, w2 -> merge(w1, w2) end)

      {_, :map, _} ->
        Map.merge(v1, v2)
    end
  end

  defp merge_message(nil, v2), do: v2
  defp merge_message(v1, nil), do: v1
  defp merge_message(v1, v2), do: merge(v1, v2)

  defp merge_scalar(:proto2, v1, nil, _default), do: v1
  defp merge_scalar(:proto3, v1, v2, default) when v2 == default, do: v1
  defp merge_scalar(_syntax, _v1, v2, _default), do: v2

  defp merge_oneof(nil, v2, _defs), do: v2
  defp merge_oneof(v1, nil, _defs), do: v1

  defp merge_oneof({v1_field, v1_value}, v2 = {v2_field, v2_value}, defs)
       when v1_field == v2_field do
    case {defs[v1_field], defs[v2_field]} do
      {{_, {:oneof, _}, {:message, _}}, {_, {:oneof, _}, {:message, _}}} ->
        {v1_field, merge(v1_value, v2_value)}

      _ ->
        v2
    end
  end

  defp merge_oneof(_v1, v2, _defs), do: v2
end
