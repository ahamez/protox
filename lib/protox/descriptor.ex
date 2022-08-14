defmodule Protox.Descriptor do
  @moduledoc false
  # Transcription of descriptor.proto. Used to bootstrap the generation process as protoc passes
  # parsed protobuf files using binary protobuf.
  # https://raw.githubusercontent.com/google/protobuf/master/src/google/protobuf/descriptor.proto

  use Protox.Define,
    enums: [
      {
        Protox.Google.Protobuf.FieldDescriptorProto.Type,
        [
          {1, :double},
          {2, :float},
          {3, :int64},
          {4, :uint64},
          {5, :int32},
          {6, :fixed64},
          {7, :fixed32},
          {8, :bool},
          {9, :string},
          {10, :group},
          {11, :message},
          {12, :bytes},
          {13, :uint32},
          {14, :enum},
          {15, :sfixed32},
          {16, :sfixed64},
          {17, :sint32},
          {18, :sint64}
        ]
      },
      {
        Protox.Google.Protobuf.FieldDescriptorProto.Label,
        [
          {1, :optional},
          {2, :required},
          {3, :repeated}
        ]
      }
    ],
    messages: [
      %Protox.Message{
        name: Protox.Google.Protobuf.FileDescriptorSet,
        syntax: :proto3,
        fields: [
          Protox.Field.new!(
            tag: 1,
            label: :repeated,
            name: :file,
            kind: :unpacked,
            type: {:message, Protox.Google.Protobuf.FileDescriptorProto}
          )
        ]
      },
      %Protox.Message{
        name: Protox.Google.Protobuf.FileDescriptorProto,
        syntax: :proto3,
        fields: [
          # Ignored: 3, 6, 8, 9, 10, 11
          Protox.Field.new!(
            tag: 1,
            label: :none,
            name: :name,
            kind: {:scalar, ""},
            type: :string
          ),
          Protox.Field.new!(
            tag: 2,
            label: :none,
            name: :package,
            kind: {:scalar, ""},
            type: :string
          ),
          Protox.Field.new!(
            tag: 4,
            label: :repeated,
            name: :message_type,
            kind: :unpacked,
            type: {:message, Protox.Google.Protobuf.DescriptorProto}
          ),
          Protox.Field.new!(
            tag: 5,
            label: :repeated,
            name: :enum_type,
            kind: :unpacked,
            type: {:message, Protox.Google.Protobuf.EnumDescriptorProto}
          ),
          Protox.Field.new!(
            tag: 7,
            label: :repeated,
            name: :extension,
            kind: :unpacked,
            type: {:message, Protox.Google.Protobuf.FieldDescriptorProto}
          ),
          Protox.Field.new!(
            tag: 8,
            label: :none,
            name: :options,
            kind: {:scalar, nil},
            type: {:message, Protox.Google.Protobuf.FileOptions}
          ),
          Protox.Field.new!(
            tag: 12,
            label: :none,
            name: :syntax,
            kind: {:scalar, ""},
            type: :string
          )
        ]
      },
      %Protox.Message{
        name: Protox.Google.Protobuf.DescriptorProto.ExtensionRange,
        syntax: :proto3,
        fields: [
          Protox.Field.new!(
            tag: 1,
            label: :none,
            name: :start,
            kind: {:scalar, 0},
            type: :int32
          ),
          Protox.Field.new!(tag: 2, label: :none, name: :end, kind: {:scalar, 0}, type: :int32)
        ]
      },
      # Protox.Google.Protobuf.DescriptorProto.ReservedRange ignored
      %Protox.Message{
        name: Protox.Google.Protobuf.DescriptorProto,
        syntax: :proto3,
        fields: [
          # Ignored: 9, 10
          Protox.Field.new!(
            tag: 1,
            label: :none,
            name: :name,
            kind: {:scalar, nil},
            type: :string
          ),
          Protox.Field.new!(
            tag: 2,
            label: :repeated,
            name: :field,
            kind: :unpacked,
            type: {:message, Protox.Google.Protobuf.FieldDescriptorProto}
          ),
          Protox.Field.new!(
            tag: 6,
            label: :repeated,
            name: :extension,
            kind: :unpacked,
            type: {:message, Protox.Google.Protobuf.FieldDescriptorProto}
          ),
          Protox.Field.new!(
            tag: 3,
            label: :repeated,
            name: :nested_type,
            kind: :unpacked,
            type: {:message, Protox.Google.Protobuf.DescriptorProto}
          ),
          Protox.Field.new!(
            tag: 4,
            label: :repeated,
            name: :enum_type,
            kind: :unpacked,
            type: {:message, Protox.Google.Protobuf.EnumDescriptorProto}
          ),
          Protox.Field.new!(
            tag: 5,
            label: :repeated,
            name: :extension_range,
            kind: :unpacked,
            type: {:message, Protox.Google.Protobuf.DescriptorProto.ExtensionRange}
          ),
          Protox.Field.new!(
            tag: 8,
            label: :repeated,
            name: :oneof_decl,
            kind: :unpacked,
            type: {:message, Protox.Google.Protobuf.OneofDescriptorProto}
          ),
          Protox.Field.new!(
            tag: 7,
            label: :none,
            name: :options,
            kind: {:scalar, nil},
            type: {:message, Protox.Google.Protobuf.MessageOptions}
          )
        ]
      },
      %Protox.Message{
        name: Protox.Google.Protobuf.FieldDescriptorProto,
        syntax: :proto3,
        fields: [
          # Ignored: 10
          Protox.Field.new!(
            tag: 1,
            label: :none,
            name: :name,
            kind: {:scalar, nil},
            type: :string
          ),
          Protox.Field.new!(
            tag: 3,
            label: :none,
            name: :number,
            kind: {:scalar, nil},
            type: :int32
          ),
          Protox.Field.new!(
            tag: 4,
            label: :none,
            name: :label,
            kind: {:scalar, nil},
            type: {:enum, Protox.Google.Protobuf.FieldDescriptorProto.Label}
          ),
          Protox.Field.new!(
            tag: 5,
            label: :none,
            name: :type,
            kind: {:scalar, nil},
            type: {:enum, Protox.Google.Protobuf.FieldDescriptorProto.Type}
          ),
          Protox.Field.new!(
            tag: 6,
            label: :none,
            name: :type_name,
            kind: {:scalar, nil},
            type: :string
          ),
          Protox.Field.new!(
            tag: 2,
            label: :none,
            name: :extendee,
            kind: {:scalar, nil},
            type: :string
          ),
          Protox.Field.new!(
            tag: 7,
            label: :none,
            name: :default_value,
            kind: {:scalar, nil},
            type: :string
          ),
          Protox.Field.new!(
            tag: 9,
            label: :none,
            name: :oneof_index,
            kind: {:scalar, nil},
            type: :int32
          ),
          Protox.Field.new!(
            tag: 8,
            label: :none,
            name: :options,
            kind: {:scalar, nil},
            type: {:message, Protox.Google.Protobuf.FieldOptions}
          ),
          Protox.Field.new!(
            tag: 17,
            label: :none,
            name: :proto3_optional,
            kind: {:scalar, false},
            type: :bool
          )
        ]
      },
      %Protox.Message{
        name: Protox.Google.Protobuf.FileOptions,
        syntax: :proto2,
        fields: [
          # Ignored: 1,8,10,20,27,9,11,16,17,18,42,31,36,37,40,41,44,45
          Protox.Field.new!(
            tag: 23,
            label: :none,
            name: :deprecated,
            kind: {:scalar, false},
            type: :bool
          ),
          Protox.Field.new!(
            tag: 999,
            label: :repeated,
            name: :uninterpreted_option,
            kind: :unpacked,
            type: {:message, Protox.Google.Protobuf.UninterpretedOption}
          )
        ]
      },
      %Protox.Message{
        name: Protox.Google.Protobuf.UninterpretedOption,
        syntax: :proto2,
        fields: [
          Protox.Field.new!(
            tag: 2,
            label: :repeated,
            name: :name,
            kind: :unpacked,
            type: {:message, Protox.Google.Protobuf.UninterpretedOption.NamePart}
          ),
          Protox.Field.new!(
            tag: 3,
            label: :none,
            name: :identifier_value,
            kind: {:scalar, nil},
            type: :string
          ),
          Protox.Field.new!(
            tag: 4,
            label: :none,
            name: :positive_int_value,
            kind: {:scalar, nil},
            type: :uint64
          ),
          Protox.Field.new!(
            tag: 5,
            label: :none,
            name: :negative_int_value,
            kind: {:scalar, nil},
            type: :int64
          ),
          Protox.Field.new!(
            tag: 6,
            label: :none,
            name: :double_value,
            kind: {:scalar, nil},
            type: :double
          ),
          Protox.Field.new!(
            tag: 7,
            label: :none,
            name: :string_value,
            kind: {:scalar, nil},
            type: :bytes
          ),
          Protox.Field.new!(
            tag: 8,
            label: :none,
            name: :aggregate_value,
            kind: {:scalar, nil},
            type: :string
          )
        ]
      },
      %Protox.Message{
        name: Protox.Google.Protobuf.UninterpretedOption.NamePart,
        syntax: :proto2,
        fields: [
          Protox.Field.new!(
            tag: 1,
            label: :none,
            name: :name_part,
            kind: {:scalar, nil},
            type: :string
          ),
          Protox.Field.new!(
            tag: 2,
            label: :none,
            name: :is_extension,
            kind: {:scalar, nil},
            type: :bool
          )
        ]
      },
      %Protox.Message{
        name: Protox.Google.Protobuf.OneofDescriptorProto,
        syntax: :proto3,
        fields: [
          # Ignored: 2
          Protox.Field.new!(
            tag: 1,
            label: :none,
            name: :name,
            kind: {:scalar, nil},
            type: :string
          )
        ]
      },
      %Protox.Message{
        name: Protox.Google.Protobuf.EnumDescriptorProto,
        syntax: :proto3,
        fields: [
          # Ignored: 3
          Protox.Field.new!(
            tag: 1,
            label: :none,
            name: :name,
            kind: {:scalar, nil},
            type: :string
          ),
          Protox.Field.new!(
            tag: 2,
            label: :repeated,
            name: :value,
            kind: :unpacked,
            type: {:message, Protox.Google.Protobuf.EnumValueDescriptorProto}
          )
        ]
      },
      %Protox.Message{
        name: Protox.Google.Protobuf.EnumValueDescriptorProto,
        syntax: :proto3,
        fields: [
          # Ignored: 3
          Protox.Field.new!(
            tag: 1,
            label: :none,
            name: :name,
            kind: {:scalar, nil},
            type: :string
          ),
          Protox.Field.new!(
            tag: 2,
            label: :none,
            name: :number,
            kind: {:scalar, nil},
            type: :int32
          )
        ]
      },
      # ServiceDescriptorProto ignored
      # MethodDescriptorProto ignored
      %Protox.Message{
        name: Protox.Google.Protobuf.MessageOptions,
        syntax: :proto3,
        fields: [
          # 1, 2, 999 ignored
          Protox.Field.new!(
            tag: 3,
            label: :none,
            name: :deprecated,
            kind: {:scalar, false},
            type: :bool
          ),
          Protox.Field.new!(
            tag: 7,
            label: :none,
            name: :map_entry,
            kind: {:scalar, false},
            type: :bool
          )
        ]
      },
      %Protox.Message{
        name: Protox.Google.Protobuf.FieldOptions,
        syntax: :proto3,
        fields: [
          # 1, 6, 5, 10, 999 ignored
          Protox.Field.new!(
            tag: 2,
            label: :none,
            name: :packed,
            kind: {:scalar, nil},
            type: :bool
          ),
          Protox.Field.new!(
            tag: 3,
            label: :none,
            name: :deprecated,
            kind: {:scalar, false},
            type: :bool
          )
        ]
      }
      # OneofOptions ignored
      # EnumOptions ignored
      # EnumValueOptions ignored
      # ServiceOptions ignored
      # MethodOptions ignored
      # SourceCodeInfo ignored
      # GeneratedCodeInfo ignored
    ]
end
