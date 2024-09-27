defmodule Protox.Parse do
  @moduledoc false
  # Internal.
  # Creates definitions from a protobuf encoded description (Protox.Google.Protobuf.FileDescriptorSet)
  # of a set of .proto files. This description is produced by `protoc`.

  alias Protox.{Field, Message}

  alias Protox.Google.Protobuf.{
    DescriptorProto,
    FieldDescriptorProto,
    FieldOptions,
    FileDescriptorSet,
    MessageOptions
  }

  @spec parse(binary, Keyword.t()) :: map()
  def parse(file_descriptor_set, opts \\ []) do
    {:ok, descriptor} = FileDescriptorSet.decode(file_descriptor_set)

    namespace_or_nil = Keyword.get(opts, :namespace)

    %{enums: %{}, messages: %{}}
    |> parse_files(descriptor.file)
    |> post_process(namespace_or_nil)
    |> remove_well_known_types()
  end

  # -- Private

  # As not all protoc installations come with the well-known types (Any, Duration, etc.),
  # protox provides these types automatically.
  # However, as user code can include those well-known types, we have to get rid of them
  # here to make sure they are not defined more than once.
  defp remove_well_known_types(acc) do
    filtered_messages =
      Enum.reject(acc.messages, fn msg = %Message{} ->
        msg.name in Google.Protobuf.well_known_types()
      end)

    filtered_enums =
      Enum.reject(acc.enums, fn {enum_name, _constants} ->
        enum_name in Google.Protobuf.well_known_types()
      end)

    %{enums: filtered_enums, messages: filtered_messages}
  end

  # Canonization: camelization, fqdn, prepend with namespace
  defp post_process(acc, namespace_or_nil) do
    processed_messages =
      for {msg_name, msg = %Message{}} <- acc.messages do
        name = Module.concat([namespace_or_nil | Enum.map(msg_name, &Macro.camelize/1)])

        fields =
          Enum.map(msg.fields, fn %Field{} = field ->
            field
            |> resolve_types(acc.enums)
            |> set_default_value(acc.enums)
            |> concat_names(namespace_or_nil)
          end)

        %Message{msg | name: name, fields: fields}
      end

    processsed_enums =
      for {ename, constants} <- acc.enums do
        {
          Module.concat([namespace_or_nil | Enum.map(ename, &Macro.camelize(&1))]),
          constants
        }
      end

    %{enums: processsed_enums, messages: processed_messages}
  end

  defp resolve_types(%Field{type: {:type_to_resolve, tname}} = field, enums) do
    if Map.has_key?(enums, tname) do
      %Field{field | type: {:enum, tname}}
    else
      %Field{field | type: {:message, tname}}
    end
  end

  defp resolve_types(
         %Field{kind: :map, type: {key_type, {:type_to_resolve, tname}}} = field,
         enums
       ) do
    if Map.has_key?(enums, tname) do
      %Field{field | type: {key_type, {:enum, tname}}}
    else
      %Field{field | type: {key_type, {:message, tname}}}
    end
  end

  defp resolve_types(%Field{} = field, _enums), do: field

  defp set_default_value(
         %Field{kind: {:scalar, :enum_default_to_resolve}, type: {:enum, ename}} = field,
         enums
       ) do
    # proto2: the first entry is always the default value
    # proto3: the entry with value 0 is the default value, and protoc mandates the first entry
    # to have the value 0
    [{_, first_is_default} | _] = Map.fetch!(enums, ename)

    %Field{field | kind: {:scalar, first_is_default}, type: {:enum, ename}}
  end

  defp set_default_value(%Field{} = field, _enums), do: field

  defp concat_names(%Field{type: {:enum, ename}} = field, namespace_or_nil) do
    %Field{field | type: {:enum, Module.concat([namespace_or_nil | ename])}}
  end

  defp concat_names(%Field{type: {:message, mname}} = field, namespace_or_nil) do
    %Field{field | type: {:message, Module.concat([namespace_or_nil | mname])}}
  end

  defp concat_names(
         %Field{kind: :map, type: {key_type, {:message, mname}}} = field,
         namespace_or_nil
       ) do
    %Field{field | type: {key_type, {:message, Module.concat([namespace_or_nil | mname])}}}
  end

  defp concat_names(%Field{type: {key_type, {:enum, ename}}} = field, namespace_or_nil) do
    %Field{field | type: {key_type, {:enum, Module.concat([namespace_or_nil | ename])}}}
  end

  defp concat_names(%Field{} = field, _), do: field

  defp parse_files(acc, descriptors) do
    Enum.reduce(descriptors, acc, fn descriptor, acc ->
      parse_file(acc, descriptor)
    end)
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
    |> make_messages(syntax, prefix, descriptor.message_type, descriptor.options)
    |> add_extensions(syntax, descriptor.extension)
  end

  defp make_enums(acc, prefix, descriptors) do
    Enum.reduce(descriptors, acc, fn descriptor, acc ->
      make_enum(acc, prefix, descriptor)
    end)
  end

  defp make_enum(acc, prefix, descriptor) do
    enum_name = prefix ++ [descriptor.name]
    enum_constants = [] |> make_enum_constants(descriptor.value) |> Enum.reverse()

    %{acc | enums: Map.put(acc.enums, enum_name, enum_constants)}
  end

  defp make_enum_constants(acc, []), do: acc

  defp make_enum_constants(acc, [descriptor | descriptors]) do
    make_enum_constants(
      [{descriptor.number, String.to_atom(descriptor.name)} | acc],
      descriptors
    )
  end

  defp make_messages(acc, syntax, prefix, descriptors, options) do
    Enum.reduce(descriptors, acc, fn descriptor, acc ->
      make_message(acc, syntax, prefix, descriptor, options)
    end)
  end

  defp make_message(
         acc,
         _syntax,
         _prefix,
         %DescriptorProto{
           options: %MessageOptions{map_entry: map_entry}
         },
         _options
       )
       when map_entry do
    # This case has already been handled in the upper message with add_maps.
    acc
  end

  defp make_message(acc, syntax, prefix, descriptor, options) do
    name = prefix ++ [descriptor.name]

    acc
    |> add_message(syntax, name, options)
    |> make_messages(syntax, name, descriptor.nested_type, options)
    |> make_enums(name, descriptor.enum_type)
    |> add_fields(descriptor, name, syntax, descriptor.field)
    |> add_fields(descriptor, name, syntax, descriptor.extension)
  end

  defp add_message(acc, syntax, name, options) do
    %{
      acc
      | messages:
          Map.put_new(acc.messages, name, %Message{
            name: name,
            syntax: syntax,
            fields: [],
            file_options: options
          })
    }
  end

  defp add_extensions(acc, syntax, fields) do
    Enum.reduce(fields, acc, fn field, acc ->
      add_field(acc, syntax, _upper = nil, fully_qualified_name(field.extendee), field)
    end)
  end

  defp add_fields(acc, upper, msg_name, syntax, fields) do
    Enum.reduce(fields, acc, fn field, acc ->
      add_field(acc, syntax, upper, msg_name, field)
    end)
  end

  defp add_field(acc, syntax, upper, msg_name, descriptor) do
    {label, kind, type} =
      case map_entry(upper, msg_name, descriptor) do
        nil ->
          type = get_type(descriptor)
          kind = get_kind(syntax, upper, descriptor)
          {field_label(descriptor), kind, type}

        map_type ->
          {nil, :map, map_type}
      end

    field =
      Field.new!(
        tag: descriptor.number,
        label: label,
        name: String.to_atom(descriptor.name),
        kind: kind,
        type: type
      )

    new_messages =
      Map.update!(acc.messages, msg_name, fn msg = %Message{} ->
        %{msg | fields: [field | msg.fields]}
      end)

    %{acc | messages: new_messages}
  end

  defp field_label(%{proto3_optional: true}), do: :proto3_optional
  defp field_label(%{label: label}), do: label

  defp map_entry(nil, _prefix, _descriptor), do: nil

  defp map_entry(
         upper,
         prefix,
         %FieldDescriptorProto{label: :repeated, type: :message} = descriptor
       ) do
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
  end

  defp map_entry(_upper, _prefix, _descriptor), do: nil

  defp fully_qualified_name(name) do
    # Make sure first element is always ".".
    true = String.starts_with?(name, ".")

    name
    |> String.split(".")
    |> tl()
    |> Enum.map(&Macro.camelize(&1))
  end

  import Protox.Guards

  defp get_kind(_syntax, upper, %FieldDescriptorProto{oneof_index: index}) when index != nil do
    parent = String.to_atom(Enum.at(upper.oneof_decl, index).name)

    {:oneof, parent}
  end

  defp get_kind(_syntax, _upper, %FieldDescriptorProto{
         label: :repeated,
         options: %FieldOptions{packed: true}
       }) do
    :packed
  end

  defp get_kind(_syntax, _upper, %FieldDescriptorProto{
         label: :repeated,
         options: %FieldOptions{packed: false}
       }) do
    :unpacked
  end

  defp get_kind(:proto3, _upper, %FieldDescriptorProto{label: :repeated, type: :enum}) do
    :packed
  end

  defp get_kind(:proto3, _upper, %FieldDescriptorProto{label: :repeated, type: ty})
       when is_primitive(ty) do
    :packed
  end

  defp get_kind(_syntax, _upper, %FieldDescriptorProto{label: :repeated}), do: :unpacked

  defp get_kind(_syntax, _upper, %FieldDescriptorProto{label: label} = descriptor)
       when label == :optional or label == :required do
    {:scalar, get_default_value(descriptor)}
  end

  defp get_type(%FieldDescriptorProto{type_name: tyname}) when tyname != nil do
    # Documentation in descriptor.proto says that it's possible that `type_name` is set, but not
    # `type`. The type will be resolved in a post-process pass.
    {:type_to_resolve, fully_qualified_name(tyname)}
  end

  defp get_type(descriptor), do: descriptor.type

  defp get_default_value(%FieldDescriptorProto{type: :enum, default_value: nil}) do
    :enum_default_to_resolve
  end

  defp get_default_value(%FieldDescriptorProto{type: :enum} = f) do
    String.to_atom(f.default_value)
  end

  defp get_default_value(%FieldDescriptorProto{type: :message}), do: nil

  defp get_default_value(%FieldDescriptorProto{type: ty, default_value: nil}) do
    Protox.Default.default(ty)
  end

  defp get_default_value(%FieldDescriptorProto{type: :bool, default_value: "true"}), do: true
  defp get_default_value(%FieldDescriptorProto{type: :bool, default_value: "false"}), do: false

  defp get_default_value(%FieldDescriptorProto{type: :string} = f), do: f.default_value
  defp get_default_value(%FieldDescriptorProto{type: :bytes} = f), do: f.default_value

  defp get_default_value(%FieldDescriptorProto{type: :double} = f) do
    f.default_value |> Float.parse() |> elem(0)
  end

  defp get_default_value(%FieldDescriptorProto{type: :float} = f) do
    f.default_value |> Float.parse() |> elem(0)
  end

  defp get_default_value(f) do
    f.default_value |> Integer.parse() |> elem(0)
  end
end
