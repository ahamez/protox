defmodule Protox.Descriptor do
  @moduledoc false
  # Transcription of descriptor.proto.
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
      {
        Protox.Google.Protobuf.FileDescriptorSet,
        :proto3,
        [
          %Protox.Field{
            tag: 1,
            label: :repeated,
            name: :file,
            kind: :unpacked,
            type: {:message, Protox.Google.Protobuf.FileDescriptorProto}
          }
        ]
      },
      {
        Protox.Google.Protobuf.FileDescriptorProto,
        :proto3,
        [
          # Ignored: 3, 6, 8, 9, 10, 11
          %Protox.Field{tag: 1, label: :none, name: :name, kind: {:default, ""}, type: :string},
          %Protox.Field{
            tag: 2,
            label: :none,
            name: :package,
            kind: {:default, ""},
            type: :string
          },
          %Protox.Field{
            tag: 4,
            label: :repeated,
            name: :message_type,
            kind: :unpacked,
            type: {:message, Protox.Google.Protobuf.DescriptorProto}
          },
          %Protox.Field{
            tag: 5,
            label: :repeated,
            name: :enum_type,
            kind: :unpacked,
            type: {:message, Protox.Google.Protobuf.EnumDescriptorProto}
          },
          %Protox.Field{
            tag: 7,
            label: :repeated,
            name: :extension,
            kind: :unpacked,
            type: {:message, Protox.Google.Protobuf.FieldDescriptorProto}
          },
          %Protox.Field{tag: 12, label: :none, name: :syntax, kind: {:default, ""}, type: :string}
        ]
      },
      {
        Protox.Google.Protobuf.DescriptorProto.ExtensionRange,
        :proto3,
        [
          %Protox.Field{tag: 1, label: :none, name: :start, kind: {:default, 0}, type: :int32},
          %Protox.Field{tag: 2, label: :none, name: :end, kind: {:default, 0}, type: :int32}
        ]
      },
      # Protox.Google.Protobuf.DescriptorProto.ReservedRange ignored
      {
        Protox.Google.Protobuf.DescriptorProto,
        :proto3,
        [
          # Ignored: 9, 10
          %Protox.Field{tag: 1, label: :none, name: :name, kind: {:default, nil}, type: :string},
          %Protox.Field{
            tag: 2,
            label: :repeated,
            name: :field,
            kind: :unpacked,
            type: {:message, Protox.Google.Protobuf.FieldDescriptorProto}
          },
          %Protox.Field{
            tag: 6,
            label: :repeated,
            name: :extension,
            kind: :unpacked,
            type: {:message, Protox.Google.Protobuf.FieldDescriptorProto}
          },
          %Protox.Field{
            tag: 3,
            label: :repeated,
            name: :nested_type,
            kind: :unpacked,
            type: {:message, Protox.Google.Protobuf.DescriptorProto}
          },
          %Protox.Field{
            tag: 4,
            label: :repeated,
            name: :enum_type,
            kind: :unpacked,
            type: {:message, Protox.Google.Protobuf.EnumDescriptorProto}
          },
          %Protox.Field{
            tag: 5,
            label: :repeated,
            name: :extension_range,
            kind: :unpacked,
            type: {:message, Protox.Google.Protobuf.DescriptorProto.ExtensionRange}
          },
          %Protox.Field{
            tag: 8,
            label: :repeated,
            name: :oneof_decl,
            kind: :unpacked,
            type: {:message, Protox.Google.Protobuf.OneofDescriptorProto}
          },
          %Protox.Field{
            tag: 7,
            label: :none,
            name: :options,
            kind: {:default, nil},
            type: {:message, Protox.Google.Protobuf.MessageOptions}
          }
        ]
      },
      {
        Protox.Google.Protobuf.FieldDescriptorProto,
        :proto3,
        [
          # Ignored: 10
          %Protox.Field{tag: 1, label: :none, name: :name, kind: {:default, nil}, type: :string},
          %Protox.Field{tag: 3, label: :none, name: :number, kind: {:default, nil}, type: :int32},
          %Protox.Field{
            tag: 4,
            label: :none,
            name: :label,
            kind: {:default, nil},
            type: {:enum, Protox.Google.Protobuf.FieldDescriptorProto.Label}
          },
          %Protox.Field{
            tag: 5,
            label: :none,
            name: :type,
            kind: {:default, nil},
            type: {:enum, Protox.Google.Protobuf.FieldDescriptorProto.Type}
          },
          %Protox.Field{
            tag: 6,
            label: :none,
            name: :type_name,
            kind: {:default, nil},
            type: :string
          },
          %Protox.Field{
            tag: 2,
            label: :none,
            name: :extendee,
            kind: {:default, nil},
            type: :string
          },
          %Protox.Field{
            tag: 7,
            label: :none,
            name: :default_value,
            kind: {:default, nil},
            type: :string
          },
          %Protox.Field{
            tag: 9,
            label: :none,
            name: :oneof_index,
            kind: {:default, nil},
            type: :int32
          },
          %Protox.Field{
            tag: 8,
            label: :none,
            name: :options,
            kind: {:default, nil},
            type: {:message, Protox.Google.Protobuf.FieldOptions}
          },
          %Protox.Field{
            tag: 17,
            label: :none,
            name: :proto3_optional,
            kind: {:default, false},
            type: :bool
          }
        ]
      },
      {
        Protox.Google.Protobuf.OneofDescriptorProto,
        :proto3,
        [
          # Ignored: 2
          %Protox.Field{tag: 1, label: :none, name: :name, kind: {:default, nil}, type: :string}
        ]
      },
      {
        Protox.Google.Protobuf.EnumDescriptorProto,
        :proto3,
        [
          # Ignored: 3
          %Protox.Field{tag: 1, label: :none, name: :name, kind: {:default, nil}, type: :string},
          %Protox.Field{
            tag: 2,
            label: :repeated,
            name: :value,
            kind: :unpacked,
            type: {:message, Protox.Google.Protobuf.EnumValueDescriptorProto}
          }
        ]
      },
      {
        Protox.Google.Protobuf.EnumValueDescriptorProto,
        :proto3,
        [
          # Ignored: 3
          %Protox.Field{tag: 1, label: :none, name: :name, kind: {:default, nil}, type: :string},
          %Protox.Field{tag: 2, label: :none, name: :number, kind: {:default, nil}, type: :int32}
        ]
      },
      # ServiceDescriptorProto ignored
      # MethodDescriptorProto ignored
      # FileOptions ignored
      {
        Protox.Google.Protobuf.MessageOptions,
        :proto3,
        [
          # 1, 2, 999 ignored
          %Protox.Field{
            tag: 3,
            label: :none,
            name: :deprecated,
            kind: {:default, false},
            type: :bool
          },
          %Protox.Field{
            tag: 7,
            label: :none,
            name: :map_entry,
            kind: {:default, false},
            type: :bool
          }
        ]
      },
      {
        Protox.Google.Protobuf.FieldOptions,
        :proto3,
        [
          # 1, 6, 5, 10, 999 ignored
          %Protox.Field{tag: 2, label: :none, name: :packed, kind: {:default, nil}, type: :bool},
          %Protox.Field{
            tag: 3,
            label: :none,
            name: :deprecated,
            kind: {:default, false},
            type: :bool
          }
        ]
      }
      # OneofOptions ignored
      # EnumOptions ignored
      # EnumValueOptions ignored
      # ServiceOptions ignored
      # MethodOptions ignored
      # UninterpretedOption ignored
      # SourceCodeInfo ignored
      # GeneratedCodeInfo ignored
    ]
end
