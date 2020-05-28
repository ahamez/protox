# credo:disable-for-this-file Credo.Check.Refactor.CyclomaticComplexity
# credo:disable-for-this-file Credo.Check.Refactor.Nesting
defmodule Protox.RandomInit do
  use PropCheck

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
  def generate_struct(mod, fields) do
    sub_msgs =
      mod.defs()
      |> Map.values()
      # Get all sub messages
      |> Enum.filter(fn {_name, kind, ty} ->
        case {kind, ty} do
          {:map, {_, {:message, _}}} -> true
          {_, {:message, _}} -> true
          _ -> false
        end
      end)
      # Transform into a map for lookup
      |> Enum.reduce(%{}, fn {field_name, kind, ty}, acc ->
        case kind do
          {:default, _} ->
            {:message, sub_msg} = ty
            Map.put(acc, field_name, {:scalar, sub_msg})

          :unpacked ->
            {:message, sub_msg} = ty
            Map.put(acc, field_name, {:repeated, sub_msg})

          :map ->
            {_, {:message, sub_msg}} = ty
            Map.put(acc, field_name, {:map, sub_msg})

          {:oneof, oneof_name} ->
            {:message, sub_msg} = ty

            Map.update(
              acc,
              oneof_name,
              # initial insertion
              {:oneof, %{field_name => sub_msg}},
              fn {:oneof, sub_map} -> {:oneof, Map.put(sub_map, field_name, sub_msg)} end
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

  def generate_fields(mod) do
    do_generate([], Map.to_list(mod.defs()))
  end

  defp do_generate_oneof(acc, oneof_name, oneof_list) do
    generators =
      Enum.map(oneof_list, fn
        # Override sub message generator get_gen/1 as it can generate a nil
        {_field, {field_name, {:oneof, _}, {:message, sub_msg}}} ->
          {field_name, generate_fields(sub_msg)}

        {_field, {field_name, {:oneof, _}, ty}} ->
          {field_name, get_gen({:default, :dummy}, ty)}
      end)

    [{oneof_name, oneof([nil | generators])} | acc]
  end

  defp do_generate(acc, []) do
    acc
  end

  defp do_generate(acc, xs = [{_field, {_name, {:oneof, oneof_name}, _ty}} | _]) do
    {oneof_list, xs} =
      Enum.split_with(xs, fn {_field, x} ->
        case x do
          {_name, {:oneof, ^oneof_name}, _ty} -> true
          _ -> false
        end
      end)

    acc
    |> do_generate_oneof(oneof_name, oneof_list)
    |> do_generate(xs)
  end

  defp do_generate(acc, [{_field, {name, kind, type}} | xs]) do
    do_generate([{name, get_gen(kind, type)} | acc], xs)
  end

  defp get_gen({:default, _}, {:enum, e}) do
    oneof(e.constants() |> Map.new() |> Map.values())
  end

  defp get_gen({:default, _}, :bool), do: bool()

  defp get_gen({:default, _}, :int32), do: integer()
  defp get_gen({:default, _}, :int64), do: integer()
  defp get_gen({:default, _}, :sint32), do: integer()
  defp get_gen({:default, _}, :sint64), do: integer()
  defp get_gen({:default, _}, :sfixed32), do: integer()
  defp get_gen({:default, _}, :sfixed64), do: integer()
  defp get_gen({:default, _}, :fixed32), do: non_neg_integer()
  defp get_gen({:default, _}, :fixed64), do: non_neg_integer()

  defp get_gen({:default, _}, :uint32), do: non_neg_integer()
  defp get_gen({:default, _}, :uint64), do: non_neg_integer()

  defp get_gen({:default, _}, :float), do: gen_float()
  defp get_gen({:default, _}, :double), do: gen_float()

  defp get_gen({:default, _}, :bytes), do: binary()
  defp get_gen({:default, _}, :string), do: utf8()

  defp get_gen({:default, _}, {:message, sub_msg}) do
    oneof([nil, generate_fields(sub_msg)])
  end

  defp get_gen(:packed, :bool), do: list(bool())
  defp get_gen(:unpacked, :bool), do: list(bool())

  defp get_gen(:packed, :int32), do: list(integer())
  defp get_gen(:packed, :int64), do: list(integer())
  defp get_gen(:packed, :sint32), do: list(integer())
  defp get_gen(:packed, :sint64), do: list(integer())
  defp get_gen(:packed, :sfixed32), do: list(integer())
  defp get_gen(:packed, :sfixed64), do: list(integer())
  defp get_gen(:packed, :fixed32), do: list(non_neg_integer())
  defp get_gen(:packed, :fixed64), do: list(non_neg_integer())
  defp get_gen(:unpacked, :int32), do: list(integer())
  defp get_gen(:unpacked, :int64), do: list(integer())
  defp get_gen(:unpacked, :sint32), do: list(integer())
  defp get_gen(:unpacked, :sint64), do: list(integer())
  defp get_gen(:unpacked, :sfixed32), do: list(integer())
  defp get_gen(:unpacked, :sfixed64), do: list(integer())
  defp get_gen(:unpacked, :fixed32), do: list(non_neg_integer())
  defp get_gen(:unpacked, :fixed64), do: list(non_neg_integer())

  defp get_gen(:packed, :uint32), do: list(non_neg_integer())
  defp get_gen(:packed, :uint64), do: list(non_neg_integer())
  defp get_gen(:unpacked, :uint32), do: list(non_neg_integer())
  defp get_gen(:unpacked, :uint64), do: list(non_neg_integer())

  defp get_gen(:packed, :float), do: list(gen_float())
  defp get_gen(:packed, :double), do: list(gen_double())
  defp get_gen(:unpacked, :float), do: list(gen_float())
  defp get_gen(:unpacked, :double), do: list(gen_double())

  defp get_gen(kind, {:enum, e}) when kind == :packed or kind == :unpacked do
    list(oneof(e.constants() |> Map.new() |> Map.values()))
  end

  defp get_gen(:unpacked, {:message, sub_msg}) do
    list(generate_fields(sub_msg))
  end

  defp get_gen(:map, {key_ty, {:message, sub_msg}}) do
    map(
      get_gen({:default, :dummy}, key_ty),
      # we don't want a nil when a message is a value in a map
      generate_fields(sub_msg)
    )
  end

  defp get_gen(:map, {key_ty, value_ty}) do
    map(
      get_gen({:default, :dummy}, key_ty),
      get_gen({:default, :dummy}, value_ty)
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
