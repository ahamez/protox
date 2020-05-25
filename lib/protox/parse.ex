defmodule Protox.Parse do
  @moduledoc false
  # Creates definitions from a protobuf encoded description (Google.Protobuf.FileDescriptorSet)
  # of a set of .proto files. This description is produced by `protoc`.

  @spec parse(binary, atom | nil) :: {[...], [...]}
  def parse(file_descriptor_set, namespace \\ nil) do
    {:ok, descriptor} = Google.Protobuf.FileDescriptorSet.decode(file_descriptor_set)

    # enums, messages
    {%{}, %{}}
    |> parse_files(descriptor.file)
    |> post_process(namespace)
  end

  # -- Private

  alias Google.Protobuf.{
    FieldDescriptorProto,
    FieldOptions
  }

  # canonization: camelization, fqdn, prepend with namespace
  defp post_process({enums, messages}, namespace) do
    processed_messages =
      for {mname, {syntax, fields}} <- messages, into: [] do
        {
          Module.concat([namespace | Enum.map(mname, &Macro.camelize(&1))]),
          syntax,
          Enum.map(
            fields,
            &(&1
              |> resolve_types(enums, messages)
              |> default_value(enums)
              |> concat_names(namespace))
          )
        }
      end

    processsed_enums =
      for {ename, constants} <- enums, into: [] do
        {
          Module.concat([namespace | Enum.map(ename, &Macro.camelize(&1))]),
          constants
        }
      end

    {processsed_enums, processed_messages}
  end

  defp resolve_types({tag, label, name, kind, {:to_resolve, tname}}, enums, _) do
    if Map.has_key?(enums, tname) do
      {tag, label, name, kind, {:enum, tname}}
    else
      {tag, label, name, kind, {:message, tname}}
    end
  end

  defp resolve_types({tag, label, name, :map, {key_type, {:to_resolve, tname}}}, enums, _) do
    if Map.has_key?(enums, tname) do
      {tag, label, name, :map, {key_type, {:enum, tname}}}
    else
      {tag, label, name, :map, {key_type, {:message, tname}}}
    end
  end

  defp resolve_types(field, _, _) do
    field
  end

  defp default_value({tag, label, name, {:default, :default_to_resolve}, {:enum, ename}}, enums) do
    # proto2: the first entry is always the default value
    # proto3: the entry with value 0 is the default value, and protoc mandates the first entry
    # to have the value 0
    [{_, first_is_default} | _] = Map.fetch!(enums, ename)
    {tag, label, name, {:default, first_is_default}, {:enum, ename}}
  end

  defp default_value(field, _) do
    field
  end

  defp concat_names({tag, label, name, kind, {:enum, ename}}, namespace) do
    {tag, label, name, kind, {:enum, Module.concat([namespace | ename])}}
  end

  defp concat_names({tag, label, name, kind, {:message, mname}}, namespace) do
    {tag, label, name, kind, {:message, Module.concat([namespace | mname])}}
  end

  defp concat_names({tag, label, name, :map, {key_type, {:message, mname}}}, namespace) do
    {tag, label, name, :map, {key_type, {:message, Module.concat([namespace | mname])}}}
  end

  defp concat_names({tag, label, name, :map, {key_type, {:enum, ename}}}, namespace) do
    {tag, label, name, :map, {key_type, {:enum, Module.concat([namespace | ename])}}}
  end

  defp concat_names(field, _) do
    field
  end

  defp parse_files(acc, []), do: acc

  defp parse_files(acc, [descriptor | descriptors]) do
    acc
    |> parse_file(descriptor)
    |> parse_files(descriptors)
  end

  defp parse_file(acc, descriptor) do
    syntax =
      case descriptor.syntax do
        "proto3" -> :proto3
        "proto2" -> :proto2
        "" -> :proto2
      end

    prefix =
      case descriptor.package do
        "" -> []
        p -> p |> String.split(".") |> Enum.map(&Macro.camelize(&1))
      end

    acc
    |> make_enums(prefix, descriptor.enum_type)
    |> make_messages(syntax, prefix, descriptor.message_type)
    |> add_extensions(nil, prefix, {syntax, descriptor.extension})
  end

  defp make_enums(acc, _, []), do: acc

  defp make_enums(acc, prefix, [descriptor | descriptors]) do
    acc
    |> make_enum(prefix, descriptor)
    |> make_enums(prefix, descriptors)
  end

  defp make_enum({enums, msgs}, prefix, descriptor) do
    {
      Map.put(
        enums,
        prefix ++ [descriptor.name],
        [] |> make_enum_constants(descriptor.value) |> Enum.reverse()
      ),
      msgs
    }
  end

  defp make_enum_constants(acc, []), do: acc

  defp make_enum_constants(acc, [descriptor | descriptors]) do
    [{descriptor.number, String.to_atom(descriptor.name)} | acc]
    |> make_enum_constants(descriptors)
  end

  defp make_messages(acc, _, _, []), do: acc

  defp make_messages(acc, syntax, prefix, [descriptor | descriptors]) do
    acc
    |> make_message(syntax, prefix, descriptor)
    |> make_messages(syntax, prefix, descriptors)
  end

  defp make_message(acc, syntax, prefix, descriptor) do
    if descriptor.options != nil and descriptor.options.map_entry do
      # This case has already been handled in the upper message with add_maps.
      acc
    else
      name = prefix ++ [descriptor.name]

      acc
      |> add_message(syntax, name)
      |> make_messages(syntax, name, descriptor.nested_type)
      |> make_enums(name, descriptor.enum_type)
      |> add_fields(descriptor, name, {syntax, descriptor.field})
      |> add_fields(descriptor, name, {syntax, descriptor.extension})
    end
  end

  defp add_message({enums, msgs}, syntax, name) do
    {
      enums,
      Map.put_new(msgs, name, {syntax, []})
    }
  end

  defp add_extensions(acc, _, _, {_, []}), do: acc

  defp add_extensions(acc, upper, prefix, {syntax, [field | fields]}) do
    acc
    |> add_field(syntax, upper, fully_qualified_name(field.extendee), field)
    |> add_extensions(upper, prefix, {syntax, fields})
  end

  defp add_fields(acc, _, _, {_, []}), do: acc

  defp add_fields(acc, upper, msg_name, {syntax, [field | fields]}) do
    acc
    |> add_field(syntax, upper, msg_name, field)
    |> add_fields(upper, msg_name, {syntax, fields})
  end

  defp add_field({enums, msgs}, syntax, upper, msg_name, descriptor) do
    {label, kind, type} =
      case map_entry(upper, msg_name, descriptor) do
        nil ->
          type = get_type(descriptor)
          kind = get_kind(syntax, upper, descriptor, type)
          {descriptor.label, kind, type}

        map_type ->
          {nil, :map, map_type}
      end

    field = {descriptor.number, label, String.to_atom(descriptor.name), kind, type}

    {
      enums,
      Map.update!(msgs, msg_name, fn {syntax, fields} -> {syntax, [field | fields]} end)
    }
  end

  defp map_entry(nil, _, _), do: nil

  defp map_entry(upper, prefix, descriptor) do
    if descriptor.label == :repeated and descriptor.type == :message do
      # Might be a map. Now find a nested type of upper that is the corresponding entry.

      res =
        Enum.find(upper.nested_type, fn m ->
          if m.options != nil and m.options.map_entry do
            m_name = prefix ++ [m.name]
            t_name = fully_qualified_name(descriptor.type_name)

            # Test if the generated name of the MapEntry message is the same as the one
            # referenced by the actual map field.
            m_name == t_name
          else
            false
          end
        end)

      case res do
        nil ->
          nil

        m ->
          key_type = Enum.find(m.field, &(&1.name == "key")).type
          value_type_field = Enum.find(m.field, &(&1.name == "value"))
          value_type = get_type(value_type_field)

          {key_type, value_type}
      end
    else
      nil
    end
  end

  defp fully_qualified_name(name) do
    # TODO. Might not start with a '.', in which case it's not fully-qualified.
    true = String.starts_with?(name, ".")
    # first element is "."
    name
    |> String.split(".")
    |> tl
    |> Enum.map(&Macro.camelize(&1))
  end

  defp get_kind(syntax, upper, descriptor, type) do
    import Protox.Guards

    case descriptor do
      %FieldDescriptorProto{oneof_index: index} when index != nil ->
        parent = Enum.at(upper.oneof_decl, index).name |> String.to_atom()
        {:oneof, parent}

      %FieldDescriptorProto{label: :repeated, options: %FieldOptions{packed: true}} ->
        :packed

      %FieldDescriptorProto{label: :repeated} ->
        case {syntax, type} do
          {:proto3, ty} when is_primitive(ty) -> :packed
          _ -> :unpacked
        end

      %FieldDescriptorProto{label: label} when label == :optional or label == :required ->
        {:default, get_default_value(descriptor)}
    end
  end

  defp get_type(%FieldDescriptorProto{type_name: tyname})
       when tyname != nil do
    # Documentation in descriptor.proto says that it's possible that `type_name` is set, but not
    # `type`. The type will be resolved in a post-process pass.
    {:to_resolve, fully_qualified_name(tyname)}
  end

  defp get_type(descriptor) do
    descriptor.type
  end

  defp get_default_value(%FieldDescriptorProto{type: :enum, default_value: nil}) do
    :default_to_resolve
  end

  defp get_default_value(f = %FieldDescriptorProto{type: :enum}) do
    String.to_atom(f.default_value)
  end

  defp get_default_value(%FieldDescriptorProto{type: :message}) do
    nil
  end

  defp get_default_value(%FieldDescriptorProto{type: ty, default_value: nil}) do
    Protox.Default.default(ty)
  end

  defp get_default_value(f = %FieldDescriptorProto{type: :bool}) do
    case f.default_value do
      "true" -> true
      "false" -> false
    end
  end

  defp get_default_value(f = %FieldDescriptorProto{type: :string}) do
    f.default_value
  end

  defp get_default_value(f = %FieldDescriptorProto{type: :bytes}) do
    f.default_value
  end

  defp get_default_value(f = %FieldDescriptorProto{type: :double}) do
    f.default_value |> Float.parse() |> elem(0)
  end

  defp get_default_value(f = %FieldDescriptorProto{type: :float}) do
    f.default_value |> Float.parse() |> elem(0)
  end

  defp get_default_value(f) do
    f.default_value |> Integer.parse() |> elem(0)
  end
end
