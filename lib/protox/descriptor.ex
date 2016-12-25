defmodule Protox.Descriptor do

  @moduledoc false
  # Transcription of descriptor.proto.
  # https://raw.githubusercontent.com/google/protobuf/master/src/google/protobuf/descriptor.proto

  use Protox.Define,
    enums: [
      {
        Google.Protobuf.FieldDescriptorProto.Type,
        [
          {0 , :ERROR},
          {1 , :double},       # TYPE_DOUBLE
          {2 , :float},        # TYPE_FLOAT
          {3 , :int64},        # TYPE_INT64
          {4 , :uint64},       # TYPE_UINT64
          {5 , :int32},        # TYPE_INT32
          {6 , :fixed64},      # TYPE_FIXED64
          {7 , :fixed32},      # TYPE_FIXED32
          {8 , :bool},         # TYPE_BOOL
          {9 , :string},       # TYPE_STRING
          {10, :group},        # TYPE_GROUP
          {11, :message},      # TYPE_MESSAGE
          {12, :bytes},        # TYPE_BYTES
          {13, :uint32},       # TYPE_UINT32
          {14, :enum},         # TYPE_ENUM
          {15, :sfixed32},     # TYPE_SFIXED32
          {16, :sfixed64},     # TYPE_SFIXED64
          {17, :sint32},       # TYPE_SINT32
          {18, :sint64},       # TYPE_SINT64
        ]
      },
      {
        Google.Protobuf.FieldDescriptorProto.Label,
        [
          {0, :ERROR},
          {1, :optional},      # LABEL_OPTIONAL
          {2, :required},      # LABEL_REQUIRED
          {3, :repeated},      # LABEL_REPEATED
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
          # Ignored: 3, 10, 11, 6, 9
          {1, :none, :name, {:default, ""}, :string},
          {2, :none, :package, {:default, ""}, :string},
          {4, :repeated, :message_type, :unpacked, {:message, Google.Protobuf.DescriptorProto}},
          {5, :repeated, :enum_type, :unpacked, {:message, Google.Protobuf.EnumDescriptorProto}},
          {7, :repeated, :extension, :unpacked, {:message, Google.Protobuf.FieldDescriptorProto}},
          {8, :none, :options, {:default, nil}, {:message, Google.Protobuf.FileOptions}},
          {12, :none, :syntax, {:default, ""}, :string},
        ]
      },
      {
        Google.Protobuf.DescriptorProto.ExtensionRange,
        [
          {1, :none, :start, {:default, 0}, :int32},
          {2, :none, :end, {:default, 0}, :int32},
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
          {5, :repeated, :extension_range, :unpacked, {:message, Google.Protobuf.DescriptorProto.ExtensionRange}},
          {8, :repeated, :oneof_decl, :unpacked, {:message, Google.Protobuf.OneofDescriptorProto}},
          {7, :none, :options, {:default, nil}, {:message, Google.Protobuf.MessageOptions}},
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
          {8, :none, :options, {:default, nil}, {:message, Google.Protobuf.FieldOptions}},
        ]
      },
      {
        Google.Protobuf.OneofDescriptorProto,
        [
          {1, :none, :name, {:default, nil}, :string},
          {2, :none, :options, {:default, nil}, {:message, Google.Protobuf.OneofOptions}},
        ]
      },
      {
        Google.Protobuf.EnumDescriptorProto,
        [
          # Ignored: 3
          {1, :none, :name, {:default, nil}, :string},
          {2, :repeated, :value, :unpacked, {:message, Google.Protobuf.EnumValueDescriptorProto}},
        ]
      },
      {
        Google.Protobuf.EnumValueDescriptorProto,
        [
          {1, :none, :name, {:default, nil}, :string},
          {2, :none, :number, {:default, nil}, :int32},
          {3, :none, :options, {:default, nil}, {:message, Google.Protobuf.EnumValueOptions}},
        ]
      },
      # Google.Protobuf.ServiceDescriptorProto ignored
      # Google.Protobuf.MethodDescriptorProto ignored
      {
        Google.Protobuf.FileOptions,
        [
          # 1, 8, 10, 20, 27, 9, 11, 16, 17, 18, 31, 36, 37, 39, 999
          {23, :none, :deprecated, {:default, false}, :bool},
        ]
      },
      {
        Google.Protobuf.MessageOptions,
        [
          # 1, 2, 999 ignored
          {3, :none, :deprecated, {:default, false}, :bool},
          {7, :none, :map_entry, {:default, false}, :bool},
        ]
      },
      {
        Google.Protobuf.FieldOptions,
        [
          # 1, 6, 5, 10, 999 ignored
          {2, :none, :packed, {:default, nil}, :bool},
          {3, :none, :deprecated, {:default, false}, :bool},
        ]
      },
      {
        Google.Protobuf.OneofOptions,
        [
          # 999 ignored
        ]
      },
      # EnumOptions ignored
      {
        Google.Protobuf.EnumValueOptions,
        [
          # 999 ignored
          {1, :none, :deprecated, {:default, false}, :bool},

        ]
      },
      # ServiceOptions ignored
      # MethodOptions ignored
      # UninterpretedOption ignored
      # SourceCodeInfo ignored
      # GeneratedCodeInfo ignored
  ]

end
