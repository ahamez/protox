# credo:disable-for-this-file Credo.Check.Refactor.CyclomaticComplexity
# credo:disable-for-this-file Credo.Check.Refactor.Nesting
defmodule Protox.RandomInit do
  @moduledoc false

  alias Google.Protobuf.{BoolValue, BytesValue, DoubleValue, Duration}
  alias Google.Protobuf.{FieldMask, FloatValue, Int32Value, Int64Value}
  alias Google.Protobuf.{ListValue, NullValue, StringValue, Struct}
  alias Google.Protobuf.{Timestamp, UInt32Value, UInt64Value, Value}
  alias Protox.{Field, OneOf, Scalar}
  alias Protox.RandomInit.EdgeCase

  def generate_msg(mod, profile \\ EdgeCase) do
    gen =
      StreamData.bind(generate_fields_values(mod, 2, profile), fn fields ->
        StreamData.constant(generate_struct(mod, fields))
      end)

    gen
    |> StreamData.resize(5)
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
          {:map, {_key_type, {:message, _msg_type}}} -> true
          {_kind, {:message, _msg_type}} -> true
          _other -> false
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
            {_key_type, {:message, sub_msg}} = field.type
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
    BoolValue,
    BytesValue,
    DoubleValue,
    Duration,
    FieldMask,
    FloatValue,
    Int32Value,
    Int64Value,
    ListValue,
    NullValue,
    StringValue,
    Struct,
    Timestamp,
    UInt32Value,
    UInt64Value,
    Value
  ]

  def generate_fields(mod, depth \\ 2, profile \\ EdgeCase) do
    do_generate([], Map.values(mod.schema().fields), depth, profile)
  end

  def generate_fields_values(mod, depth \\ 2, profile \\ EdgeCase) do
    resolve_generators(generate_fields(mod, depth, profile))
  end

  defp resolve_generators(%StreamData{} = gen), do: gen

  defp resolve_generators(term) when is_list(term) do
    Enum.reduce(Enum.reverse(term), StreamData.constant([]), fn elem, acc_gen ->
      StreamData.bind(resolve_generators(elem), fn v ->
        StreamData.map(acc_gen, fn acc -> [v | acc] end)
      end)
    end)
  end

  defp resolve_generators(term) when is_map(term) do
    term
    |> Map.to_list()
    |> resolve_generators()
    |> StreamData.map(&Map.new/1)
  end

  defp resolve_generators(term) when is_tuple(term) do
    term
    |> Tuple.to_list()
    |> resolve_generators()
    |> StreamData.map(&List.to_tuple/1)
  end

  defp resolve_generators(term), do: StreamData.constant(term)

  defp do_generate(acc, _fields, 0, _profile), do: acc
  defp do_generate(acc, [], _depth, _profile), do: acc

  defp do_generate(acc, [%Field{kind: %OneOf{parent: oneof_name}} | _rest] = fields, depth, profile) do
    {oneof_list, fields} =
      Enum.split_with(fields, fn %Field{} = field ->
        case field.kind do
          %OneOf{parent: ^oneof_name} -> true
          _other_kind -> false
        end
      end)

    acc
    |> do_generate_oneof(oneof_name, oneof_list, depth, profile)
    |> do_generate(fields, depth, profile)
  end

  defp do_generate(acc, [field | fields], depth, profile) do
    do_generate([{field.name, get_gen(profile, depth, field.kind, field.type)} | acc], fields, depth, profile)
  end

  defp do_generate_oneof(acc, oneof_name, oneof_list, depth, profile) do
    generators =
      Enum.map(oneof_list, fn %Field{kind: %OneOf{parent: _parent}} = field ->
        gen = get_gen(profile, depth, %Scalar{default_value: :dummy}, field.type)
        StreamData.map(gen, fn v -> {field.name, v} end)
      end)

    [{oneof_name, StreamData.one_of([StreamData.constant(nil) | generators])} | acc]
  end

  # Every leaf distribution comes from the profile; what stays here is the schema
  # traversal: which fields exist, how oneofs nest, and when recursion stops.

  defp get_gen(_profile, _depth, %Scalar{}, {:message, sub_msg}) when sub_msg in @well_known_types do
    nil
  end

  defp get_gen(profile, depth, %Scalar{}, {:message, sub_msg}) do
    profile.presence(generate_fields_values(sub_msg, depth - 1, profile), depth - 1)
  end

  defp get_gen(profile, _depth, %Scalar{}, type), do: profile.scalar(type)

  defp get_gen(_profile, _depth, :unpacked, {:message, sub_msg}) when sub_msg in @well_known_types do
    []
  end

  defp get_gen(profile, depth, :unpacked, {:message, sub_msg}) do
    profile.collection(generate_fields_values(sub_msg, depth - 1, profile), depth - 1)
  end

  defp get_gen(profile, depth, kind, type) when kind in [:packed, :unpacked] do
    profile.collection(profile.scalar(type), depth)
  end

  defp get_gen(_profile, _depth, :map, {_key_ty, {:message, sub_msg}}) when sub_msg in @well_known_types do
    %{}
  end

  defp get_gen(profile, depth, :map, {key_ty, {:message, sub_msg}}) do
    profile.map(key_ty, profile.scalar(key_ty), generate_fields_values(sub_msg, depth - 1, profile))
  end

  defp get_gen(profile, _depth, :map, {key_ty, value_ty}) do
    profile.map(key_ty, profile.scalar(key_ty), profile.scalar(value_ty))
  end
end
