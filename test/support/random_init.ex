# credo:disable-for-this-file Credo.Check.Refactor.CyclomaticComplexity
# credo:disable-for-this-file Credo.Check.Refactor.Nesting
defmodule Protox.RandomInit do
  @moduledoc false

  import StreamData

  alias Protox.{Field, OneOf, Scalar}

  def generate_msg(mod) do
    gen =
      bind(generate_fields(mod), fn fields ->
        constant(generate_struct(mod, fields))
      end)

    gen |> resize(5) |> Enum.at(0)
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
          %Scalar{} ->
            {:message, sub_msg} = field.type
            Map.put(acc, field.name, %Scalar{default_value: sub_msg})

          :unpacked ->
            {:message, sub_msg} = field.type
            Map.put(acc, field.name, {:repeated, sub_msg})

          :map ->
            {_, {:message, sub_msg}} = field.type
            Map.put(acc, field.name, {:map, sub_msg})

          %OneOf{parent: oneof_name} ->
            {:message, sub_msg} = field.type

            Map.update(
              acc,
              oneof_name,
              # initial insertion
              %OneOf{parent: %{field.name => sub_msg}},
              fn %OneOf{parent: sub_map} ->
                %OneOf{parent: Map.put(sub_map, field.name, sub_msg)}
              end
            )
        end
      end)

    new_fields =
      Enum.reduce(fields, [], fn {field_name, val}, acc ->
        case sub_msgs[field_name] do
          # Not a sub message, no transformation and recursion needed
          nil ->
            [{field_name, val} | acc]

          %OneOf{parent: sub_map} ->
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

          %Scalar{default_value: sub_msg} ->
            if val == nil do
              [{field_name, nil} | acc]
            else
              [{field_name, generate_struct(sub_msg, val)} | acc]
            end

          {:map, sub_msg} ->
            val =
              val
              |> Map.new(fn {k, msg_val} -> {k, generate_struct(sub_msg, msg_val)} end)

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

  defp do_generate(acc, _fields, 0), do: constant(acc)
  defp do_generate(acc, [], _depth), do: constant(acc)

  defp do_generate(acc, [%Field{kind: %OneOf{parent: oneof_name}} | _] = fields, depth) do
    {oneof_list, fields} =
      Enum.split_with(fields, fn %Field{} = field ->
        case field.kind do
          %OneOf{parent: ^oneof_name} -> true
          _ -> false
        end
      end)

    bind(do_generate_oneof(acc, oneof_name, oneof_list, depth), fn acc ->
      do_generate(acc, fields, depth)
    end)
  end

  defp do_generate(acc, [field | fields], depth) do
    bind(get_gen(depth, field.kind, field.type), fn val ->
      do_generate([{field.name, val} | acc], fields, depth)
    end)
  end

  defp do_generate_oneof(acc, oneof_name, oneof_list, depth) do
    generators =
      Enum.map(oneof_list, fn %Field{kind: %OneOf{parent: _}} = field ->
        map(get_gen(depth, %Scalar{default_value: :dummy}, field.type), fn val ->
          {field.name, val}
        end)
      end)

    bind(one_of([constant(nil) | generators]), fn
      nil ->
        constant([{oneof_name, nil} | acc])

      {field_name, val} ->
        constant([{oneof_name, {field_name, val}} | acc])
    end)
  end

  defp get_gen(_depth, %Scalar{}, {:enum, e}) do
    e.constants() |> Map.new() |> Map.values() |> one_of()
  end

  defp get_gen(_depth, %Scalar{}, :bool), do: boolean()

  defp get_gen(_depth, %Scalar{}, :int32), do: integer()
  defp get_gen(_depth, %Scalar{}, :int64), do: integer()
  defp get_gen(_depth, %Scalar{}, :sint32), do: integer()
  defp get_gen(_depth, %Scalar{}, :sint64), do: integer()
  defp get_gen(_depth, %Scalar{}, :sfixed32), do: integer()
  defp get_gen(_depth, %Scalar{}, :sfixed64), do: integer()
  defp get_gen(_depth, %Scalar{}, :fixed32), do: non_negative_integer()
  defp get_gen(_depth, %Scalar{}, :fixed64), do: non_negative_integer()

  defp get_gen(_depth, %Scalar{}, :uint32), do: non_negative_integer()
  defp get_gen(_depth, %Scalar{}, :uint64), do: non_negative_integer()

  defp get_gen(_depth, %Scalar{}, :float), do: gen_float()
  defp get_gen(_depth, %Scalar{}, :double), do: gen_float()

  defp get_gen(_depth, %Scalar{}, :bytes), do: binary()
  defp get_gen(_depth, %Scalar{}, :string), do: string(:printable)

  defp get_gen(_depth, %Scalar{}, {:message, sub_msg}) when sub_msg in @well_known_types do
    constant(nil)
  end

  defp get_gen(depth, %Scalar{}, {:message, sub_msg}) do
    one_of([constant(nil), generate_fields(sub_msg, depth - 1)])
  end

  defp get_gen(_depth, :packed, :bool), do: list_of(boolean())
  defp get_gen(_depth, :unpacked, :bool), do: list_of(boolean())

  defp get_gen(_depth, :packed, :int32), do: list_of(integer())
  defp get_gen(_depth, :packed, :int64), do: list_of(integer())
  defp get_gen(_depth, :packed, :sint32), do: list_of(integer())
  defp get_gen(_depth, :packed, :sint64), do: list_of(integer())
  defp get_gen(_depth, :packed, :sfixed32), do: list_of(integer())
  defp get_gen(_depth, :packed, :sfixed64), do: list_of(integer())
  defp get_gen(_depth, :packed, :fixed32), do: list_of(non_negative_integer())
  defp get_gen(_depth, :packed, :fixed64), do: list_of(non_negative_integer())
  defp get_gen(_depth, :unpacked, :int32), do: list_of(integer())
  defp get_gen(_depth, :unpacked, :int64), do: list_of(integer())
  defp get_gen(_depth, :unpacked, :sint32), do: list_of(integer())
  defp get_gen(_depth, :unpacked, :sint64), do: list_of(integer())
  defp get_gen(_depth, :unpacked, :sfixed32), do: list_of(integer())
  defp get_gen(_depth, :unpacked, :sfixed64), do: list_of(integer())
  defp get_gen(_depth, :unpacked, :fixed32), do: list_of(non_negative_integer())
  defp get_gen(_depth, :unpacked, :fixed64), do: list_of(non_negative_integer())

  defp get_gen(_depth, :packed, :uint32), do: list_of(non_negative_integer())
  defp get_gen(_depth, :packed, :uint64), do: list_of(non_negative_integer())
  defp get_gen(_depth, :unpacked, :uint32), do: list_of(non_negative_integer())
  defp get_gen(_depth, :unpacked, :uint64), do: list_of(non_negative_integer())

  defp get_gen(_depth, :packed, :float), do: list_of(gen_float())
  defp get_gen(_depth, :packed, :double), do: list_of(gen_double())
  defp get_gen(_depth, :unpacked, :float), do: list_of(gen_float())
  defp get_gen(_depth, :unpacked, :double), do: list_of(gen_double())

  defp get_gen(_depth, kind, {:enum, e}) when kind == :packed or kind == :unpacked do
    e.constants() |> Map.new() |> Map.values() |> one_of() |> list_of()
  end

  defp get_gen(_depth, :unpacked, :string), do: list_of(string(:printable))
  defp get_gen(_depth, :unpacked, :bytes), do: list_of(binary())

  defp get_gen(_depth, :unpacked, {:message, sub_msg}) when sub_msg in @well_known_types do
    constant([])
  end

  defp get_gen(depth, :unpacked, {:message, sub_msg}) do
    list_of(generate_fields(sub_msg, depth - 1))
  end

  defp get_gen(_depth, :map, {_key_ty, {:message, sub_msg}}) when sub_msg in @well_known_types do
    constant(%{})
  end

  defp get_gen(depth, :map, {key_ty, {:message, sub_msg}}) do
    map_of(
      get_gen(depth, %Scalar{default_value: :dummy}, key_ty),
      generate_fields(sub_msg, depth - 1)
    )
  end

  defp get_gen(depth, :map, {key_ty, value_ty}) do
    map_of(
      get_gen(depth, %Scalar{default_value: :dummy}, key_ty),
      get_gen(depth, %Scalar{default_value: :dummy}, value_ty)
    )
  end

  # ----------------------

  defp gen_float() do
    one_of([integer(), constant(:nan), constant(:infinity), constant(:"-infinity")])
  end

  defp gen_double() do
    one_of([float(), constant(:nan), constant(:infinity), constant(:"-infinity")])
  end
end
