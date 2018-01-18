defmodule Protox.Descriptor do
  @moduledoc false
  # Transcription of descriptor.proto.
  # https://raw.githubusercontent.com/google/protobuf/master/src/google/protobuf/descriptor.proto

  use Protox.Define,
    enums: [
      {
        Google.Protobuf.FieldDescriptorProto.Type,
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
        Google.Protobuf.FieldDescriptorProto.Label,
        [
          {1, :optional},
          {2, :required},
          {3, :repeated}
        ]
      }
    ],
    messages: [
      {
        Google.Protobuf.FileDescriptorSet,
        [
          {1, :repeated, :file, :unpacked, {:message, Google.Protobuf.FileDescriptorProto}}
        ]
      },
      {
        Google.Protobuf.FileDescriptorProto,
        [
          # Ignored: 3, 6, 8, 9, 10, 11
          {1, :none, :name, {:default, ""}, :string},
          {2, :none, :package, {:default, ""}, :string},
          {4, :repeated, :message_type, :unpacked, {:message, Google.Protobuf.DescriptorProto}},
          {5, :repeated, :enum_type, :unpacked, {:message, Google.Protobuf.EnumDescriptorProto}},
          {7, :repeated, :extension, :unpacked, {:message, Google.Protobuf.FieldDescriptorProto}},
          {12, :none, :syntax, {:default, ""}, :string}
        ]
      },
      {
        Google.Protobuf.DescriptorProto.ExtensionRange,
        [
          {1, :none, :start, {:default, 0}, :int32},
          {2, :none, :end, {:default, 0}, :int32}
        ]
      },
      # Google.Protobuf.DescriptorProto.ReservedRange ignored
      {
        Google.Protobuf.DescriptorProto,
        [
          # Ignored: 9, 10
          {1, :none, :name, {:default, nil}, :string},
          {2, :repeated, :field, :unpacked, {:message, Google.Protobuf.FieldDescriptorProto}},
          {6, :repeated, :extension, :unpacked, {:message, Google.Protobuf.FieldDescriptorProto}},
          {3, :repeated, :nested_type, :unpacked, {:message, Google.Protobuf.DescriptorProto}},
          {4, :repeated, :enum_type, :unpacked, {:message, Google.Protobuf.EnumDescriptorProto}},
          {5, :repeated, :extension_range, :unpacked,
           {:message, Google.Protobuf.DescriptorProto.ExtensionRange}},
          {8, :repeated, :oneof_decl, :unpacked, {:message, Google.Protobuf.OneofDescriptorProto}},
          {7, :none, :options, {:default, nil}, {:message, Google.Protobuf.MessageOptions}}
        ]
      },
      {
        Google.Protobuf.FieldDescriptorProto,
        [
          # Ignored: 10
          {1, :none, :name, {:default, nil}, :string},
          {3, :none, :number, {:default, nil}, :int32},
          {4, :none, :label, {:default, nil}, {:enum, Google.Protobuf.FieldDescriptorProto.Label}},
          {5, :none, :type, {:default, nil}, {:enum, Google.Protobuf.FieldDescriptorProto.Type}},
          {6, :none, :type_name, {:default, nil}, :string},
          {2, :none, :extendee, {:default, nil}, :string},
          {7, :none, :default_value, {:default, nil}, :string},
          {9, :none, :oneof_index, {:default, nil}, :int32},
          {8, :none, :options, {:default, nil}, {:message, Google.Protobuf.FieldOptions}}
        ]
      },
      {
        Google.Protobuf.OneofDescriptorProto,
        [
          # Ignored: 2
          {1, :none, :name, {:default, nil}, :string}
        ]
      },
      {
        Google.Protobuf.EnumDescriptorProto,
        [
          # Ignored: 3
          {1, :none, :name, {:default, nil}, :string},
          {2, :repeated, :value, :unpacked, {:message, Google.Protobuf.EnumValueDescriptorProto}}
        ]
      },
      {
        Google.Protobuf.EnumValueDescriptorProto,
        [
          # Ignored: 3
          {1, :none, :name, {:default, nil}, :string},
          {2, :none, :number, {:default, nil}, :int32}
        ]
      },
      # ServiceDescriptorProto ignored
      # MethodDescriptorProto ignored
      # FileOptions ignored
      {
        Google.Protobuf.MessageOptions,
        [
          # 1, 2, 999 ignored
          {3, :none, :deprecated, {:default, false}, :bool},
          {7, :none, :map_entry, {:default, false}, :bool}
        ]
      },
      {
        Google.Protobuf.FieldOptions,
        [
          # 1, 6, 5, 10, 999 ignored
          {2, :none, :packed, {:default, nil}, :bool},
          {3, :none, :deprecated, {:default, false}, :bool}
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
