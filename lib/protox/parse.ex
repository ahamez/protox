defmodule Protox.Parse do
  @moduledoc false
  # Internal.
  # Creates definitions from a protobuf encoded description (Protox.Google.Protobuf.FileDescriptorSet)
  # of a set of .proto files. This description is produced by `protoc`.

  import Protox.Guards

  alias Protox.{Definition, Field, MessageSchema, OneOf, Scalar}

  alias Protox.Google.Protobuf.{
    DescriptorProto,
    FieldDescriptorProto,
    FieldOptions,
    FileDescriptorProto,
    FileDescriptorSet,
    MessageOptions
  }

  @spec parse(binary(), Keyword.t()) :: {:ok, Definition.t()}
  def parse(file_descriptor_set, opts \\ []) do
    {:ok, descriptor} = FileDescriptorSet.decode(file_descriptor_set)

    definition =
      %Definition{}
      |> parse_files(descriptor.file)
      |> post_process(opts)
      |> add_file_options()
      |> remove_google_types()

    {:ok, definition}
  end

  # -- Private

  defp parse_files(definition, descriptors) do
    Enum.reduce(
      descriptors,
      definition,
      fn %FileDescriptorProto{} = descriptor, definition -> parse_file(definition, descriptor) end
    )
  end

  defp parse_file(definition, %FileDescriptorProto{} = descriptor) do
    syntax =
      case descriptor.syntax do
        "proto3" -> :proto3
        "proto2" -> :proto2
        "" -> :proto2
      end

    prefix =
      case descriptor.package do
        "" -> []
        p -> p |> String.split(".") |> camelize()
      end

    definition
    |> make_enums(prefix, descriptor.enum_type)
    |> make_messages(syntax, prefix, descriptor.message_type, descriptor.options)
    |> add_extensions(syntax, descriptor.extension)
  end

  # Prepend with namespace, resolve pending types and set default values
  defp post_process(definition, opts) do
    namespace_or_nil = Keyword.get(opts, :namespace, nil)

    processed_messages =
      for {msg_name, %MessageSchema{} = msg} <- definition.messages_schemas, into: %{} do
        name = Module.concat([namespace_or_nil | msg_name])

        fields =
          for {field_name, field} <- msg.fields, into: %{} do
            field =
              field
              |> resolve_types(definition.enums_schemas)
              |> set_default_value(definition.enums_schemas)
              |> concat_names(namespace_or_nil)

            {field_name, field}
          end

        {name, %MessageSchema{msg | name: name, fields: fields}}
      end

    processsed_enums =
      for {ename, constants} <- definition.enums_schemas, into: %{} do
        {Module.concat([namespace_or_nil | ename]), constants}
      end

    %Definition{enums_schemas: processsed_enums, messages_schemas: processed_messages}
  end

  # We remove all Google types as:
  # - they're either well-known types (Any, Timestamp, etc.) which are provided with protox.
  # - or they come from descriptor.proto, which are only relevant (as far as I know) protox.
  # Removing these types permit to generate smaller code.
  defp remove_google_types(definition) do
    filtered_messages =
      Map.reject(definition.messages_schemas, fn {msg_name, _message} ->
        match?(["Google", "Protobuf" | _], Module.split(msg_name))
      end)

    filtered_enums =
      Map.reject(definition.enums_schemas, fn {enum_name, _constants} ->
        match?(["Google", "Protobuf" | _], Module.split(enum_name))
      end)

    %Definition{enums_schemas: filtered_enums, messages_schemas: filtered_messages}
  end

  defp add_file_options(definition) do
    # Custom file options are defined by users, so they can't be described in
    # the FileOptions of descriptor.ex. They are parsed as unknown fields.
    # So, to decode these custom fields, we have to compile the FileOptions
    # which comes with the current FileDescriptorSet.

    # Look for FileOptions and related messages. If found, we will compile them
    # to parse file options.
    {file_options_messages, other_messages} =
      Map.split(definition.messages_schemas, [
        Google.Protobuf.FeatureSet,
        Google.Protobuf.FileOptions,
        Google.Protobuf.UninterpretedOption,
        Google.Protobuf.UninterpretedOption.NamePart
      ])

    case file_options_messages do
      file_options_message when map_size(file_options_message) == 0 ->
        definition

      _ ->
        # If FileOptions and other related message have been found, we also need
        # to compile their associated enums.
        {file_options_optimize_enum, other_enums} =
          Map.split(definition.enums_schemas, [
            Google.Protobuf.FeatureSet.EnumType,
            Google.Protobuf.FeatureSet.FieldPresence,
            Google.Protobuf.FeatureSet.JsonFormat,
            Google.Protobuf.FeatureSet.MessageEncoding,
            Google.Protobuf.FeatureSet.RepeatedFieldEncoding,
            Google.Protobuf.FeatureSet.Utf8Validation,
            Google.Protobuf.FileOptions.OptimizeMode
          ])

        # Compile the needed modules.
        %Definition{
          messages_schemas: file_options_messages,
          enums_schemas: file_options_optimize_enum
        }
        |> Protox.Define.define()
        |> Code.eval_quoted()

        # We can now parse the unknown fields with the modules compiled above.
        # Also, we transform this FileOptions into a bare map so as to not depend
        # on the FileOptions type which is not necessary for the end user.
        other_messages =
          for {msg_name, msg} <- other_messages, into: %{} do
            file_options =
              msg.file_options
              |> Protox.Google.Protobuf.FileOptions.encode!()
              |> elem(_bytes_position_in_tuple = 0)
              |> IO.iodata_to_binary()
              |> then(&apply(Google.Protobuf.FileOptions, :decode!, [&1]))
              |> Map.from_struct()

            {msg_name, %{msg | file_options: file_options}}
          end

        # It's no longer necessary to keep the compiled modules in memory as they are of
        # no use for end user.
        remove_module(Google.Protobuf.FeatureSet)
        remove_module(Google.Protobuf.FileOptions)
        remove_module(Google.Protobuf.UninterpretedOption)
        remove_module(Google.Protobuf.UninterpretedOption.NamePart)
        remove_module(Google.Protobuf.FeatureSet.EnumType)
        remove_module(Google.Protobuf.FeatureSet.FieldPresence)
        remove_module(Google.Protobuf.FeatureSet.JsonFormat)
        remove_module(Google.Protobuf.FeatureSet.MessageEncoding)
        remove_module(Google.Protobuf.FeatureSet.RepeatedFieldEncoding)
        remove_module(Google.Protobuf.FeatureSet.Utf8Validation)
        remove_module(Google.Protobuf.FileOptions.OptimizeMode)

        # Finally, construct a new definition with the messages and enums that were not used
        # to parse FileOptions.
        definition
        |> put_in([Access.key!(:messages_schemas)], other_messages)
        |> put_in([Access.key!(:enums_schemas)], other_enums)
    end
  end

  defp resolve_types(%Field{type: {:type_to_resolve, tname}} = field, enums) do
    if Map.has_key?(enums, tname) do
      %Field{field | type: {:enum, tname}}
    else
      %Field{field | type: {:message, tname}}
    end
  end

  defp resolve_types(%Field{kind: :map, type: {key_type, {:type_to_resolve, tname}}} = field, enums) do
    if Map.has_key?(enums, tname) do
      %Field{field | type: {key_type, {:enum, tname}}}
    else
      %Field{field | type: {key_type, {:message, tname}}}
    end
  end

  defp resolve_types(%Field{} = field, _enums), do: field

  defp set_default_value(
         %Field{kind: %Scalar{default_value: :enum_default_to_resolve}, type: {:enum, ename}} = field,
         enums
       ) do
    # proto2: the first entry is always the default value
    # proto3: the entry with value 0 is the default value, and protoc mandates the first entry
    # to have the value 0
    [{_, first_is_default} | _] = Map.fetch!(enums, ename)

    %Field{field | kind: %Scalar{default_value: first_is_default}, type: {:enum, ename}}
  end

  defp set_default_value(%Field{} = field, _enums), do: field

  defp concat_names(%Field{type: {:enum, ename}} = field, namespace_or_nil) do
    %Field{field | type: {:enum, Module.concat([namespace_or_nil | ename])}}
  end

  defp concat_names(%Field{type: {:message, mname}} = field, namespace_or_nil) do
    %Field{field | type: {:message, Module.concat([namespace_or_nil | mname])}}
  end

  defp concat_names(%Field{kind: :map, type: {key_type, {:message, mname}}} = field, namespace_or_nil) do
    %Field{field | type: {key_type, {:message, Module.concat([namespace_or_nil | mname])}}}
  end

  defp concat_names(%Field{type: {key_type, {:enum, ename}}} = field, namespace_or_nil) do
    %Field{field | type: {key_type, {:enum, Module.concat([namespace_or_nil | ename])}}}
  end

  defp concat_names(%Field{} = field, _), do: field

  defp make_enums(definition, prefix, descriptors) do
    Enum.reduce(descriptors, definition, fn descriptor, definition ->
      make_enum(definition, prefix, descriptor)
    end)
  end

  defp make_enum(definition, prefix, descriptor) do
    enum_name = prefix ++ camelize([descriptor.name])
    enum_constants = Enum.map(descriptor.value, &{&1.number, String.to_atom(&1.name)})

    put_in(definition, [Access.key!(:enums_schemas), enum_name], enum_constants)
  end

  defp make_messages(definition, syntax, prefix, descriptors, file_options) do
    Enum.reduce(descriptors, definition, fn descriptor, definition ->
      make_message(definition, syntax, prefix, descriptor, file_options)
    end)
  end

  defp make_message(
         definition,
         _syntax,
         _prefix,
         %DescriptorProto{options: %MessageOptions{map_entry: map_entry}},
         _file_options
       )
       when map_entry do
    # This case has already been handled in the upper message with add_maps.
    definition
  end

  defp make_message(definition, syntax, prefix, descriptor, file_options) do
    msg_name = prefix ++ camelize([descriptor.name])

    definition
    |> add_message(syntax, msg_name, file_options)
    |> make_messages(syntax, msg_name, descriptor.nested_type, file_options)
    |> make_enums(msg_name, descriptor.enum_type)
    |> add_fields(descriptor, msg_name, syntax, descriptor.field)
    |> add_fields(descriptor, msg_name, syntax, descriptor.extension)
  end

  defp add_message(definition, syntax, name, file_options) do
    put_in(definition, [Access.key!(:messages_schemas), name], %MessageSchema{
      name: name,
      syntax: syntax,
      fields: %{},
      file_options: file_options
    })
  end

  defp add_extensions(definition, syntax, fields) do
    Enum.reduce(fields, definition, fn field, definition ->
      add_field(definition, syntax, _upper = nil, fully_qualified_name(field.extendee), field)
    end)
  end

  defp add_fields(definition, upper, msg_name, syntax, fields) do
    Enum.reduce(fields, definition, fn field, definition ->
      add_field(definition, syntax, upper, msg_name, field)
    end)
  end

  defp add_field(definition, syntax, upper, msg_name, descriptor) do
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

    put_in(
      definition,
      [Access.key!(:messages_schemas), msg_name, Access.key!(:fields), field.name],
      field
    )
  end

  defp field_label(%{proto3_optional: true}), do: :proto3_optional
  defp field_label(%{label: label}), do: label

  defp map_entry(nil, _prefix, _descriptor), do: nil

  defp map_entry(upper, prefix, %FieldDescriptorProto{label: :repeated, type: :message} = descriptor) do
    # Might be a map. Now find a nested type of upper that is the corresponding entry.
    search_nested_type =
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

    case search_nested_type do
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
    |> camelize()
  end

  defp get_kind(_syntax, upper, %FieldDescriptorProto{oneof_index: index}) when index != nil do
    %OneOf{parent: String.to_atom(Enum.at(upper.oneof_decl, index).name)}
  end

  defp get_kind(_syntax, _upper, %FieldDescriptorProto{label: :repeated, options: %FieldOptions{packed: true}}) do
    :packed
  end

  defp get_kind(_syntax, _upper, %FieldDescriptorProto{label: :repeated, options: %FieldOptions{packed: false}}) do
    :unpacked
  end

  defp get_kind(:proto3, _upper, %FieldDescriptorProto{label: :repeated, type: :enum}) do
    :packed
  end

  defp get_kind(:proto3, _upper, %FieldDescriptorProto{label: :repeated, type: ty}) when is_primitive(ty) do
    :packed
  end

  defp get_kind(_syntax, _upper, %FieldDescriptorProto{label: :repeated}), do: :unpacked

  defp get_kind(_syntax, _upper, %FieldDescriptorProto{label: label} = descriptor)
       when label == :optional or label == :required do
    %Scalar{default_value: get_default_value(descriptor)}
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

  defp camelize(name) when is_list(name) do
    Enum.map(name, &Macro.camelize/1)
  end

  defp remove_module(module) when is_atom(module) do
    :code.delete(module)
    :code.purge(module)
  end
end
