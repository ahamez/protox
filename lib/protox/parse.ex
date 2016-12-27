defmodule Protox.Parse do

  @moduledoc """
  Parse a protobuf encoded description (Google.Protobuf.FileDescriptorSet)
  of a set of .proto files This description is produced by `protoc`.
  """

  def parse(file_descriptor_set) do
    {:ok, descriptor} = Google.Protobuf.FileDescriptorSet.decode(file_descriptor_set)

    {%{}, %{}} # enums, messages
    |> parse_files(descriptor.file)
    |> post_process()
  end


  # -- Private


  alias Google.Protobuf.{
    FieldDescriptorProto,
    FieldOptions,
  }


  defp post_process({enums, messages}) do
    enums_p = Enum.reduce(enums, [],
      fn ({enum_name, constants}, acc) ->
         [{Module.concat(enum_name), constants} | acc]
      end)

    messages_p = Enum.reduce(messages, [],
      fn ({msg_name, defs}, acc) ->
        defs_p = Enum.map(defs, &post_process_pass(enums, &1))
        [{Module.concat(msg_name), defs_p} | acc]
      end)

    {enums_p, messages_p}
  end


  defp post_process_pass(enums, {tag, label, name, {:default, :default_value_to_resolve}, {:enum, ename}}) do
    [{_, first_is_default} | _] = Map.fetch!(enums, ename)
    {tag, label, name, {:default, first_is_default}, {:enum, Module.concat(ename)}}
  end
  defp post_process_pass(_, {tag, label, name, kind, {enum_or_msg, m_name}})
  when enum_or_msg == :message or enum_or_msg == :enum
  do
    {tag, label, name, kind, {enum_or_msg, Module.concat(m_name)}}
  end
  defp post_process_pass(_, {tag, label, name, :map, {key_type, {enum_or_msg, m_name}}})
  when enum_or_msg == :message or enum_or_msg == :enum
  do
    {tag, label, name, :map, {key_type, {enum_or_msg, Module.concat(m_name)}}}
  end
  defp post_process_pass(_, defs) do
    defs
  end


  defp parse_files(acc, []), do: acc
  defp parse_files(acc, [descriptor | descriptors]) do
    acc
    |> parse_file(descriptor)
    |> parse_files(descriptors)
  end


  defp parse_file(acc, descriptor) do
    syntax = case descriptor.syntax do
      "proto3" -> :proto3
      "proto2" -> :proto2
      ""       -> :proto2
    end

    prefix = case descriptor.package do
      "" -> []
      p  -> p |> String.split(".") |> Enum.map(&Macro.camelize(&1))
    end

    acc
    |> make_enums(prefix, descriptor.enum_type)
    |> make_messages(syntax, prefix, descriptor.message_type)
    |> add_extensions(syntax, nil, prefix, descriptor.extension)
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
        make_enum_constants([], descriptor.value) |> Enum.reverse()
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
      |> make_messages(syntax, name, descriptor.nested_type)
      |> make_enums(name, descriptor.enum_type)
      |> add_fields(syntax, descriptor, name, descriptor.field)
      |> add_fields(syntax, descriptor, name, descriptor.extension)
    end
  end


  defp add_extensions(acc, _, _, _, []), do: acc
  defp add_extensions(acc, syntax, upper, prefix, [field | fields]) do
    acc
    |> add_field(syntax, upper, fq_name(prefix, field.extendee), field)
    |> add_extensions(syntax, upper, prefix, fields)
  end


  defp add_fields(acc, _, _, _, []), do: acc
  defp add_fields(acc, syntax, upper, msg_name, [field | fields]) do
    acc
    |> add_field(syntax, upper, msg_name, field)
    |> add_fields(syntax, upper, msg_name, fields)
  end


  defp add_field({enums, msgs}, syntax, upper, msg_name, descriptor) do
    {label, kind, type} = case map_entry(upper, msg_name, descriptor) do
      nil ->
        type = get_type(msg_name, descriptor)
        kind = get_kind(syntax, upper, descriptor, type)
        {descriptor.label, kind, type}

      map_type ->
        {nil, :map, map_type}
    end

    field =  {descriptor.number, label, String.to_atom(descriptor.name), kind, type}

    {enums, Map.update(msgs, msg_name, [field], &([field|&1]))}
  end


  defp map_entry(nil, _, _), do: nil
  defp map_entry(upper, prefix, descriptor) do
    if descriptor.label == :repeated and descriptor.type == :message do
      # Might be a map. Now find an nested type of upper that is the corresponding entry.

      res = Enum.find(upper.nested_type,
        fn m ->
          if m.options != nil and m.options.map_entry do
            m_name = prefix ++ [m.name]
            t_name = fq_name(prefix, descriptor.type_name)

            # Test if the generated name of the MapEntry message is the same as the one
            #  referenced by the actual map field.
            m_name == t_name
          else
            false
          end
        end)

      case res do
        nil ->
          nil

        m ->
          key_type   = Enum.find(m.field, &(&1.name == "key")).type
          value_type_field = Enum.find(m.field, &(&1.name == "value"))
          value_type = get_type(prefix, value_type_field)

          {key_type, value_type}
      end

    else
      nil
    end
  end


  defp fq_name(_prefix, name) do
    # TODO. Might not start with a '.', in which case it's not fully-qualified.
    # Can this really happen?
    name
    |> String.split(".")
    |> tl # first element is "."
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
          _                                   -> :unpacked
        end

      %FieldDescriptorProto{label: label} when label == :optional or label == :required ->
        {:default, get_default_value(syntax, descriptor)}

      _ -> :todo

    end
  end


  defp get_type(prefix, %FieldDescriptorProto{type_name: tyname, type: type})
  when tyname != nil and type != nil
  do
    {type, fq_name(prefix, tyname)}
  end
  defp get_type(prefix, %FieldDescriptorProto{type_name: tyname})
  when tyname != nil do
    # Documentation in descriptor.proto says that it's possible that `type_name` is set, but not
    # `type`. In this case, we'll have to resolve the type in a post-process pass.
    # TODO.
    {:type_to_resolve, fq_name(prefix, tyname)}
  end
  defp get_type(_, descriptor) do
    descriptor.type
  end


  defp get_default_value(:proto3, %FieldDescriptorProto{type: :enum}) do
    # Real default value will be resolved in a post-process pass as the corresponding enum might
    # not exist yet.
    :default_value_to_resolve
  end
  defp get_default_value(:proto3, %FieldDescriptorProto{type: :message}) do
    nil
  end
  defp get_default_value(:proto3, descriptor) do
    Protox.Default.default(descriptor.type)
  end
  defp get_default_value(:proto2, %FieldDescriptorProto{type: :enum, default_value: nil}) do
    nil
  end
  defp get_default_value(:proto2, f = %FieldDescriptorProto{type: :enum}) do
    String.to_atom(f.default_value)
  end
  defp get_default_value(:proto2, %FieldDescriptorProto{default_value: nil}) do
    nil
  end
  defp get_default_value(:proto2, %FieldDescriptorProto{type: :bool, default_value: "true"}) do
    true
  end
  defp get_default_value(:proto2, %FieldDescriptorProto{type: :bool, default_value: "false"}) do
    false
  end
  defp get_default_value(:proto2, f = %FieldDescriptorProto{type: :string}) do
    f.default_value
  end
  defp get_default_value(:proto2, f = %FieldDescriptorProto{type: :bytes}) do
    # TODO. Transform C escaped value (all bytes >= 128 are escaped) into a binary
    f.default_value
  end
  defp get_default_value(:proto2, f = %FieldDescriptorProto{type: :double}) do
    {value, _} = Float.parse(f.default_value)
    value
  end
  defp get_default_value(:proto2, f = %FieldDescriptorProto{type: :float}) do
    {value, _} = Float.parse(f.default_value)
    value
  end
  defp get_default_value(:proto2, f) do
    {value, _} = Integer.parse(f.default_value)
    value
  end

end
