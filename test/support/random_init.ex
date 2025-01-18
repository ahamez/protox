# credo:disable-for-this-file Credo.Check.Refactor.CyclomaticComplexity
# credo:disable-for-this-file Credo.Check.Refactor.Nesting
defmodule Protox.RandomInit do
  @moduledoc false

  use PropCheck

  alias Protox.Field

  def generate_msg(mod) do
    gen =
      let fields <- generate_fields(mod) do
        generate_struct(mod, fields)
      end

    {:ok, msg} = :proper_gen.pick(gen)

    msg
  end

  # ------------------------------------------------------------------- #

  # Recursively generate the sub messages of mod
  def generate_struct(mod, nil), do: struct!(mod)

  def generate_struct(mod, fields) when is_list(fields) do
    sub_msgs =
      mod.schema().fields
      |> Map.values()
      # Get all sub messages
      |> Enum.filter(fn %Field{} = field ->
        case {field.kind, field.type} do
          {:map, {_, {:message, _}}} -> true
          {_, {:message, _}} -> true
          _ -> false
        end
      end)
      # Transform into a map for lookup
      |> Enum.reduce(%{}, fn %Field{} = field, acc ->
        case field.kind do
          {:scalar, _} ->
            {:message, sub_msg} = field.type
            Map.put(acc, field.name, {:scalar, sub_msg})

          :unpacked ->
            {:message, sub_msg} = field.type
            Map.put(acc, field.name, {:repeated, sub_msg})

          :map ->
            {_, {:message, sub_msg}} = field.type
            Map.put(acc, field.name, {:map, sub_msg})

          {:oneof, oneof_name} ->
            {:message, sub_msg} = field.type

            Map.update(
              acc,
              oneof_name,
              # initial insertion
              {:oneof, %{field.name => sub_msg}},
              fn {:oneof, sub_map} -> {:oneof, Map.put(sub_map, field.name, sub_msg)} end
            )
        end
      end)

    new_fields =
      Enum.reduce(fields, [], fn {field_name, val}, acc ->
        case sub_msgs[field_name] do
          # Not a sub message, no transformation and recursion needed
          nil ->
            [{field_name, val} | acc]

          {:oneof, sub_map} ->
            if val == nil do
              [{field_name, nil} | acc]
            else
              {sub_field_name, val} = val

              case sub_map[sub_field_name] do
                # the enclosing oneof contains one sub message, but sub_map does not
                # know about sub non-messages entries, thus we need to add them manually
                nil ->
                  [{field_name, {sub_field_name, val}} | acc]

                sub_msg ->
                  [{field_name, {sub_field_name, generate_struct(sub_msg, val)}} | acc]
              end
            end

          {:scalar, sub_msg} ->
            if val == nil do
              [{field_name, nil} | acc]
            else
              [{field_name, generate_struct(sub_msg, val)} | acc]
            end

          {:map, sub_msg} ->
            val =
              val
              |> Enum.map(fn {k, msg_val} -> {k, generate_struct(sub_msg, msg_val)} end)
              |> Map.new()

            [{field_name, val} | acc]

          {:repeated, sub_msg} ->
            val = Enum.map(val, fn msg_val -> generate_struct(sub_msg, msg_val) end)
            [{field_name, val} | acc]
        end
      end)

    struct!(mod, new_fields)
  end

  # ------------------------------------------------------------------- #

  @well_known_types [
    Google.Protobuf.BoolValue,
    Google.Protobuf.BytesValue,
    Google.Protobuf.DoubleValue,
    Google.Protobuf.Duration,
    Google.Protobuf.FieldMask,
    Google.Protobuf.FloatValue,
    Google.Protobuf.Int32Value,
    Google.Protobuf.Int64Value,
    Google.Protobuf.ListValue,
    Google.Protobuf.NullValue,
    Google.Protobuf.StringValue,
    Google.Protobuf.Struct,
    Google.Protobuf.Timestamp,
    Google.Protobuf.UInt32Value,
    Google.Protobuf.UInt64Value,
    Google.Protobuf.Value
  ]

  def generate_fields(mod, depth \\ 2) do
    do_generate([], Map.values(mod.schema().fields), depth)
  end

  defp do_generate(acc, _fields, 0), do: acc
  defp do_generate(acc, [], _depth), do: acc

  defp do_generate(acc, [%Field{kind: {:oneof, oneof_name}} | _] = fields, depth) do
    {oneof_list, fields} =
      Enum.split_with(fields, fn field = %Field{} ->
        case field.kind do
          {:oneof, ^oneof_name} -> true
          _ -> false
        end
      end)

    acc
    |> do_generate_oneof(oneof_name, oneof_list, depth)
    |> do_generate(fields, depth)
  end

  defp do_generate(acc, [field | fields], depth) do
    do_generate([{field.name, get_gen(depth, field.kind, field.type)} | acc], fields, depth)
  end

  defp do_generate_oneof(acc, oneof_name, oneof_list, depth) do
    generators =
      Enum.map(oneof_list, fn field = %Field{kind: {:oneof, _}} ->
        {field.name, get_gen(depth, {:scalar, :dummy}, field.type)}
      end)

    [{oneof_name, oneof([nil | generators])} | acc]
  end

  defp get_gen(_depth, {:scalar, _}, {:enum, e}) do
    oneof(e.constants() |> Map.new() |> Map.values())
  end

  defp get_gen(_depth, {:scalar, _}, :bool), do: bool()

  defp get_gen(_depth, {:scalar, _}, :int32), do: integer()
  defp get_gen(_depth, {:scalar, _}, :int64), do: integer()
  defp get_gen(_depth, {:scalar, _}, :sint32), do: integer()
  defp get_gen(_depth, {:scalar, _}, :sint64), do: integer()
  defp get_gen(_depth, {:scalar, _}, :sfixed32), do: integer()
  defp get_gen(_depth, {:scalar, _}, :sfixed64), do: integer()
  defp get_gen(_depth, {:scalar, _}, :fixed32), do: non_neg_integer()
  defp get_gen(_depth, {:scalar, _}, :fixed64), do: non_neg_integer()

  defp get_gen(_depth, {:scalar, _}, :uint32), do: non_neg_integer()
  defp get_gen(_depth, {:scalar, _}, :uint64), do: non_neg_integer()

  defp get_gen(_depth, {:scalar, _}, :float), do: gen_float()
  defp get_gen(_depth, {:scalar, _}, :double), do: gen_float()

  defp get_gen(_depth, {:scalar, _}, :bytes), do: binary()
  defp get_gen(_depth, {:scalar, _}, :string), do: utf8()

  defp get_gen(_depth, {:scalar, _}, {:message, sub_msg}) when sub_msg in @well_known_types do
    nil
  end

  defp get_gen(depth, {:scalar, _}, {:message, sub_msg}) do
    oneof([nil, generate_fields(sub_msg, depth - 1)])
  end

  defp get_gen(_depth, :packed, :bool), do: list(bool())
  defp get_gen(_depth, :unpacked, :bool), do: list(bool())

  defp get_gen(_depth, :packed, :int32), do: list(integer())
  defp get_gen(_depth, :packed, :int64), do: list(integer())
  defp get_gen(_depth, :packed, :sint32), do: list(integer())
  defp get_gen(_depth, :packed, :sint64), do: list(integer())
  defp get_gen(_depth, :packed, :sfixed32), do: list(integer())
  defp get_gen(_depth, :packed, :sfixed64), do: list(integer())
  defp get_gen(_depth, :packed, :fixed32), do: list(non_neg_integer())
  defp get_gen(_depth, :packed, :fixed64), do: list(non_neg_integer())
  defp get_gen(_depth, :unpacked, :int32), do: list(integer())
  defp get_gen(_depth, :unpacked, :int64), do: list(integer())
  defp get_gen(_depth, :unpacked, :sint32), do: list(integer())
  defp get_gen(_depth, :unpacked, :sint64), do: list(integer())
  defp get_gen(_depth, :unpacked, :sfixed32), do: list(integer())
  defp get_gen(_depth, :unpacked, :sfixed64), do: list(integer())
  defp get_gen(_depth, :unpacked, :fixed32), do: list(non_neg_integer())
  defp get_gen(_depth, :unpacked, :fixed64), do: list(non_neg_integer())

  defp get_gen(_depth, :packed, :uint32), do: list(non_neg_integer())
  defp get_gen(_depth, :packed, :uint64), do: list(non_neg_integer())
  defp get_gen(_depth, :unpacked, :uint32), do: list(non_neg_integer())
  defp get_gen(_depth, :unpacked, :uint64), do: list(non_neg_integer())

  defp get_gen(_depth, :packed, :float), do: list(gen_float())
  defp get_gen(_depth, :packed, :double), do: list(gen_double())
  defp get_gen(_depth, :unpacked, :float), do: list(gen_float())
  defp get_gen(_depth, :unpacked, :double), do: list(gen_double())

  defp get_gen(_depth, kind, {:enum, e}) when kind == :packed or kind == :unpacked do
    list(oneof(e.constants() |> Map.new() |> Map.values()))
  end

  defp get_gen(_depth, :unpacked, :string), do: list(utf8())
  defp get_gen(_depth, :unpacked, :bytes), do: list(binary())

  defp get_gen(_depth, :unpacked, {:message, sub_msg}) when sub_msg in @well_known_types do
    []
  end

  defp get_gen(depth, :unpacked, {:message, sub_msg}) do
    list(generate_fields(sub_msg, depth - 1))
  end

  defp get_gen(_depth, :map, {_key_ty, {:message, sub_msg}}) when sub_msg in @well_known_types do
    %{}
  end

  defp get_gen(depth, :map, {key_ty, {:message, sub_msg}}) do
    map(
      get_gen(depth, {:scalar, :dummy}, key_ty),
      # we don't want a nil when a message is a value in a map
      generate_fields(sub_msg, depth - 1)
    )
  end

  defp get_gen(depth, :map, {key_ty, value_ty}) do
    map(
      get_gen(depth, {:scalar, :dummy}, key_ty),
      get_gen(depth, {:scalar, :dummy}, value_ty)
    )
  end

  # ----------------------

  defp gen_float() do
    oneof([integer(), :nan, :infinity, :"-infinity"])
  end

  defp gen_double() do
    oneof([float(), :nan, :infinity, :"-infinity"])
  end
end
