defmodule Protox.Message do
  @doc """
  Singular fields of `msg` will be overwritten, if specified in `from`, except for
  embedded messages which will be merged. Repeated fields will be concatenated.

  Note that "specified" means a different thing in protobuf 2 and 3:
  - 2: if the singular field from `from` is nil, the value from `msg` is kept
  - 3: if the singular field from `from` is set to the default value, the value from `msg` is kept
  This behaviour matches the C++ reference implementation behaviour.

  `msg` and `from` must be of the same type
  """
  @spec merge(struct, struct) :: struct
  def merge(msg, from) do
    defs = msg.__struct__.defs_by_name()
    syntax = msg.__struct__.syntax()

    Map.merge(msg, from, fn name, v1, v2 ->
      if name == :__struct__ or name == msg.__struct__.get_unknown_fields_name() do
        v1
      else
        case defs[name] do
          {_, :packed, _} ->
            v1 ++ v2

          {_, :unpacked, _} ->
            v1 ++ v2

          {_, {:default, _}, {:message, _}} ->
            case {v1, v2} do
              {nil, v} -> v
              {_, nil} -> nil
              _ -> merge(v1, v2)
            end

          {_, {:default, _}, _} ->
            case {syntax, v1, v2} do
              # v2 is not set in protobuf2 message
              {:proto2, ^v1, nil} ->
                v1

              {:proto3, ^v1, ^v2} ->
                {:ok, default} = msg.__struct__.default(name)

                if v2 == default do
                  # when v2 is set to the default value, the C++ reference implementation
                  # keeps v1
                  v1
                else
                  v2
                end

              {_, _, ^v2} ->
                v2
            end

          # It's a oneof as `name` is not in defs
          nil ->
            case {v1, v2} do
              {nil, v} ->
                v

              {_, nil} ->
                nil

              {{v1_field, v1_value}, {v2_field, v2_value}} when v1_field == v2_field ->
                case {defs[v1_field], defs[v2_field]} do
                  {{_, {:oneof, _}, {:message, _}}, {_, {:oneof, _}, {:message, _}}} ->
                    {v1_field, merge(v1_value, v2_value)}

                  _ ->
                    v2
                end

              _ ->
                v2
            end

          {_, :map, {_, {:message, _}}} ->
            Map.merge(v1, v2, fn _k, w1, w2 -> merge(w1, w2) end)

          {_, :map, _} ->
            Map.merge(v1, v2)
        end
      end
    end)
  end
end
