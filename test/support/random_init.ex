# credo:disable-for-this-file Credo.Check.Refactor.CyclomaticComplexity
# credo:disable-for-this-file Credo.Check.Refactor.Nesting
defmodule Protox.RandomInit do
  @moduledoc false

  import Bitwise

  alias Protox.{Field, OneOf, Scalar}
  alias StreamData, as: SD

  def generate_msg(mod) do
    gen =
      SD.bind(generate_fields_values(mod), fn fields ->
        SD.constant(generate_struct(mod, fields))
      end)

    gen
    |> SD.resize(5)
    |> Enum.at(0)
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
              Map.new(val, fn {k, msg_val} -> {k, generate_struct(sub_msg, msg_val)} end)

            [{field_name, val} | acc]

          {:repeated, sub_msg} ->
            val =
              Enum.map(val, fn msg_val -> generate_struct(sub_msg, msg_val) end)

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

  def generate_fields_values(mod, depth \\ 2) do
    generate_fields(mod, depth) |> resolve_generators()
  end

  defp resolve_generators(%StreamData{} = gen), do: gen

  defp resolve_generators(term) when is_list(term) do
    Enum.reduce(Enum.reverse(term), SD.constant([]), fn elem, acc_gen ->
      SD.bind(resolve_generators(elem), fn v ->
        SD.map(acc_gen, fn acc -> [v | acc] end)
      end)
    end)
  end

  defp resolve_generators(term) when is_map(term) do
    term
    |> Map.to_list()
    |> resolve_generators()
    |> SD.map(&Map.new/1)
  end

  defp resolve_generators(term) when is_tuple(term) do
    term
    |> Tuple.to_list()
    |> resolve_generators()
    |> SD.map(&List.to_tuple/1)
  end

  defp resolve_generators(term), do: SD.constant(term)

  defp do_generate(acc, _fields, 0), do: acc
  defp do_generate(acc, [], _depth), do: acc

  defp do_generate(acc, [%Field{kind: %OneOf{parent: oneof_name}} | _] = fields, depth) do
    {oneof_list, fields} =
      Enum.split_with(fields, fn %Field{} = field ->
        case field.kind do
          %OneOf{parent: ^oneof_name} -> true
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
      Enum.map(oneof_list, fn %Field{kind: %OneOf{parent: _}} = field ->
        gen = get_gen(depth, %Scalar{default_value: :dummy}, field.type)
        SD.map(gen, fn v -> {field.name, v} end)
      end)

    [{oneof_name, SD.one_of([SD.constant(nil) | generators])} | acc]
  end

  defp get_gen(_depth, %Scalar{}, {:enum, e}) do
    e.constants() |> Map.new() |> Map.values() |> SD.member_of()
  end

  defp get_gen(_depth, %Scalar{}, :bool), do: SD.boolean()

  defp get_gen(_depth, %Scalar{}, :int32), do: SD.integer()
  defp get_gen(_depth, %Scalar{}, :int64), do: SD.integer()
  defp get_gen(_depth, %Scalar{}, :sint32), do: SD.integer()
  defp get_gen(_depth, %Scalar{}, :sint64), do: SD.integer()
  defp get_gen(_depth, %Scalar{}, :sfixed32), do: SD.integer()
  defp get_gen(_depth, %Scalar{}, :sfixed64), do: SD.integer()
  defp get_gen(_depth, %Scalar{}, :fixed32), do: SD.integer(0..((1 <<< 32) - 1))
  defp get_gen(_depth, %Scalar{}, :fixed64), do: SD.integer(0..((1 <<< 64) - 1))

  defp get_gen(_depth, %Scalar{}, :uint32), do: SD.integer(0..((1 <<< 32) - 1))
  defp get_gen(_depth, %Scalar{}, :uint64), do: SD.integer(0..((1 <<< 64) - 1))

  defp get_gen(_depth, %Scalar{}, :float), do: gen_float()
  defp get_gen(_depth, %Scalar{}, :double), do: gen_double()

  defp get_gen(_depth, %Scalar{}, :bytes), do: SD.binary()
  defp get_gen(_depth, %Scalar{}, :string), do: SD.string(:printable)

  defp get_gen(_depth, %Scalar{}, {:message, sub_msg}) when sub_msg in @well_known_types do
    nil
  end

  defp get_gen(depth, %Scalar{}, {:message, sub_msg}) do
    SD.one_of([SD.constant(nil), generate_fields_values(sub_msg, depth - 1)])
  end

  defp get_gen(_depth, :packed, :bool), do: SD.list_of(SD.boolean())
  defp get_gen(_depth, :unpacked, :bool), do: SD.list_of(SD.boolean())

  defp get_gen(_depth, :packed, :int32), do: SD.list_of(SD.integer())
  defp get_gen(_depth, :packed, :int64), do: SD.list_of(SD.integer())
  defp get_gen(_depth, :packed, :sint32), do: SD.list_of(SD.integer())
  defp get_gen(_depth, :packed, :sint64), do: SD.list_of(SD.integer())
  defp get_gen(_depth, :packed, :sfixed32), do: SD.list_of(SD.integer())
  defp get_gen(_depth, :packed, :sfixed64), do: SD.list_of(SD.integer())
  defp get_gen(_depth, :packed, :fixed32), do: SD.list_of(SD.integer(0..((1 <<< 32) - 1)))
  defp get_gen(_depth, :packed, :fixed64), do: SD.list_of(SD.integer(0..((1 <<< 64) - 1)))
  defp get_gen(_depth, :unpacked, :int32), do: SD.list_of(SD.integer())
  defp get_gen(_depth, :unpacked, :int64), do: SD.list_of(SD.integer())
  defp get_gen(_depth, :unpacked, :sint32), do: SD.list_of(SD.integer())
  defp get_gen(_depth, :unpacked, :sint64), do: SD.list_of(SD.integer())
  defp get_gen(_depth, :unpacked, :sfixed32), do: SD.list_of(SD.integer())
  defp get_gen(_depth, :unpacked, :sfixed64), do: SD.list_of(SD.integer())
  defp get_gen(_depth, :unpacked, :fixed32), do: SD.list_of(SD.integer(0..((1 <<< 32) - 1)))
  defp get_gen(_depth, :unpacked, :fixed64), do: SD.list_of(SD.integer(0..((1 <<< 64) - 1)))

  defp get_gen(_depth, :packed, :uint32), do: SD.list_of(SD.integer(0..((1 <<< 32) - 1)))
  defp get_gen(_depth, :packed, :uint64), do: SD.list_of(SD.integer(0..((1 <<< 64) - 1)))
  defp get_gen(_depth, :unpacked, :uint32), do: SD.list_of(SD.integer(0..((1 <<< 32) - 1)))
  defp get_gen(_depth, :unpacked, :uint64), do: SD.list_of(SD.integer(0..((1 <<< 64) - 1)))

  defp get_gen(_depth, :packed, :float), do: SD.list_of(gen_float())
  defp get_gen(_depth, :packed, :double), do: SD.list_of(gen_double())
  defp get_gen(_depth, :unpacked, :float), do: SD.list_of(gen_float())
  defp get_gen(_depth, :unpacked, :double), do: SD.list_of(gen_double())

  defp get_gen(_depth, kind, {:enum, e}) when kind == :packed or kind == :unpacked do
    e.constants() |> Map.new() |> Map.values() |> SD.member_of() |> SD.list_of()
  end

  defp get_gen(_depth, :unpacked, :string), do: SD.list_of(SD.string(:printable))
  defp get_gen(_depth, :unpacked, :bytes), do: SD.list_of(SD.binary())

  defp get_gen(_depth, :unpacked, {:message, sub_msg}) when sub_msg in @well_known_types do
    []
  end

  defp get_gen(depth, :unpacked, {:message, sub_msg}) do
    SD.list_of(generate_fields_values(sub_msg, depth - 1))
  end

  defp get_gen(_depth, :map, {_key_ty, {:message, sub_msg}}) when sub_msg in @well_known_types do
    %{}
  end

  defp get_gen(depth, :map, {key_ty, {:message, sub_msg}}) do
    key_gen = get_gen(depth, %Scalar{default_value: :dummy}, key_ty)
    val_gen = generate_fields_values(sub_msg, depth - 1)
    map_of_for_keys(key_ty, key_gen, val_gen)
  end

  defp get_gen(depth, :map, {key_ty, value_ty}) do
    key_gen = get_gen(depth, %Scalar{default_value: :dummy}, key_ty)
    val_gen = get_gen(depth, %Scalar{default_value: :dummy}, value_ty)
    map_of_for_keys(key_ty, key_gen, val_gen)
  end

  defp map_of_for_keys(key_ty, key_gen, val_gen) do
    case key_ty do
      :bool -> SD.map_of(key_gen, val_gen, max_length: 2, max_tries: 50)
      {:enum, e} -> SD.map_of(key_gen, val_gen, max_length: length(e.constants()), max_tries: 50)
      _ -> SD.map_of(key_gen, val_gen, max_length: 20, max_tries: 50)
    end
  end

  # ----------------------

  defp gen_float() do
    SD.one_of([
      SD.map(SD.integer(-10_000..10_000), &(&1 * 1.0)),
      SD.constant(:nan),
      SD.constant(:infinity),
      SD.constant(:"-infinity")
    ])
  end

  defp gen_double() do
    SD.one_of([
      SD.float(),
      SD.constant(:nan),
      SD.constant(:infinity),
      SD.constant(:"-infinity")
    ])
  end
end
