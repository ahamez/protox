defmodule Protox.Descriptor do
  @moduledoc false
  # Transcription of descriptor.proto. Used to bootstrap the generation process as protoc passes
  # parsed protobuf files using binary protobuf.
  # https://raw.githubusercontent.com/google/protobuf/master/src/google/protobuf/descriptor.proto

  use Protox.Define,
    enums: %{
      Protox.Google.Protobuf.FieldDescriptorProto.Type => [
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
      ],
      Protox.Google.Protobuf.FieldDescriptorProto.Label => [
        {1, :optional},
        {2, :required},
        {3, :repeated}
      ],
      Protox.Google.Protobuf.FileOptions.OptimizeMode => [
        {1, :SPEED},
        {2, :CODE_SIZE},
        {3, :LITE_RUNTIME}
      ]
    },
    messages: %{
      Protox.Google.Protobuf.FileDescriptorSet => %Protox.Message{
        name: Protox.Google.Protobuf.FileDescriptorSet,
        syntax: :proto3,
        fields: %{
          file:
            Protox.Field.new!(
              tag: 1,
              label: :repeated,
              name: :file,
              kind: :unpacked,
              type: {:message, Protox.Google.Protobuf.FileDescriptorProto}
            )
        }
      },
      Protox.Google.Protobuf.FileDescriptorProto => %Protox.Message{
        name: Protox.Google.Protobuf.FileDescriptorProto,
        syntax: :proto3,
        fields: %{
          # Ignored: 3, 6, 9, 10, 11
          name:
            Protox.Field.new!(
              tag: 1,
              label: :none,
              name: :name,
              kind: {:scalar, ""},
              type: :string
            ),
          package:
            Protox.Field.new!(
              tag: 2,
              label: :none,
              name: :package,
              kind: {:scalar, ""},
              type: :string
            ),
          message_type:
            Protox.Field.new!(
              tag: 4,
              label: :repeated,
              name: :message_type,
              kind: :unpacked,
              type: {:message, Protox.Google.Protobuf.DescriptorProto}
            ),
          enum_type:
            Protox.Field.new!(
              tag: 5,
              label: :repeated,
              name: :enum_type,
              kind: :unpacked,
              type: {:message, Protox.Google.Protobuf.EnumDescriptorProto}
            ),
          extension:
            Protox.Field.new!(
              tag: 7,
              label: :repeated,
              name: :extension,
              kind: :unpacked,
              type: {:message, Protox.Google.Protobuf.FieldDescriptorProto}
            ),
          options:
            Protox.Field.new!(
              tag: 8,
              label: :none,
              name: :options,
              kind: {:scalar, nil},
              type: {:message, Protox.Google.Protobuf.FileOptions}
            ),
          syntax:
            Protox.Field.new!(
              tag: 12,
              label: :none,
              name: :syntax,
              kind: {:scalar, ""},
              type: :string
            )
        }
      },
      Protox.Google.Protobuf.DescriptorProto.ExtensionRange => %Protox.Message{
        name: Protox.Google.Protobuf.DescriptorProto.ExtensionRange,
        syntax: :proto3,
        fields: %{
          start:
            Protox.Field.new!(
              tag: 1,
              label: :none,
              name: :start,
              kind: {:scalar, 0},
              type: :int32
            ),
          end:
            Protox.Field.new!(
              tag: 2,
              label: :none,
              name: :end,
              kind: {:scalar, 0},
              type: :int32
            )
        }
      },
      # Protox.Google.Protobuf.DescriptorProto.ReservedRange ignored
      Protox.Google.Protobuf.DescriptorProto => %Protox.Message{
        name: Protox.Google.Protobuf.DescriptorProto,
        syntax: :proto3,
        fields: %{
          # Ignored: 9, 10
          name:
            Protox.Field.new!(
              tag: 1,
              label: :none,
              name: :name,
              kind: {:scalar, nil},
              type: :string
            ),
          field:
            Protox.Field.new!(
              tag: 2,
              label: :repeated,
              name: :field,
              kind: :unpacked,
              type: {:message, Protox.Google.Protobuf.FieldDescriptorProto}
            ),
          extension:
            Protox.Field.new!(
              tag: 6,
              label: :repeated,
              name: :extension,
              kind: :unpacked,
              type: {:message, Protox.Google.Protobuf.FieldDescriptorProto}
            ),
          nested_type:
            Protox.Field.new!(
              tag: 3,
              label: :repeated,
              name: :nested_type,
              kind: :unpacked,
              type: {:message, Protox.Google.Protobuf.DescriptorProto}
            ),
          enum_type:
            Protox.Field.new!(
              tag: 4,
              label: :repeated,
              name: :enum_type,
              kind: :unpacked,
              type: {:message, Protox.Google.Protobuf.EnumDescriptorProto}
            ),
          extension_range:
            Protox.Field.new!(
              tag: 5,
              label: :repeated,
              name: :extension_range,
              kind: :unpacked,
              type: {:message, Protox.Google.Protobuf.DescriptorProto.ExtensionRange}
            ),
          oneof_decl:
            Protox.Field.new!(
              tag: 8,
              label: :repeated,
              name: :oneof_decl,
              kind: :unpacked,
              type: {:message, Protox.Google.Protobuf.OneofDescriptorProto}
            ),
          options:
            Protox.Field.new!(
              tag: 7,
              label: :none,
              name: :options,
              kind: {:scalar, nil},
              type: {:message, Protox.Google.Protobuf.MessageOptions}
            )
        }
      },
      Protox.Google.Protobuf.FieldDescriptorProto => %Protox.Message{
        name: Protox.Google.Protobuf.FieldDescriptorProto,
        syntax: :proto3,
        fields: %{
          # Ignored: 10
          name:
            Protox.Field.new!(
              tag: 1,
              label: :none,
              name: :name,
              kind: {:scalar, nil},
              type: :string
            ),
          number:
            Protox.Field.new!(
              tag: 3,
              label: :none,
              name: :number,
              kind: {:scalar, nil},
              type: :int32
            ),
          label:
            Protox.Field.new!(
              tag: 4,
              label: :none,
              name: :label,
              kind: {:scalar, nil},
              type: {:enum, Protox.Google.Protobuf.FieldDescriptorProto.Label}
            ),
          type:
            Protox.Field.new!(
              tag: 5,
              label: :none,
              name: :type,
              kind: {:scalar, nil},
              type: {:enum, Protox.Google.Protobuf.FieldDescriptorProto.Type}
            ),
          type_name:
            Protox.Field.new!(
              tag: 6,
              label: :none,
              name: :type_name,
              kind: {:scalar, nil},
              type: :string
            ),
          extendee:
            Protox.Field.new!(
              tag: 2,
              label: :none,
              name: :extendee,
              kind: {:scalar, nil},
              type: :string
            ),
          default_value:
            Protox.Field.new!(
              tag: 7,
              label: :none,
              name: :default_value,
              kind: {:scalar, nil},
              type: :string
            ),
          oneof_index:
            Protox.Field.new!(
              tag: 9,
              label: :none,
              name: :oneof_index,
              kind: {:scalar, nil},
              type: :int32
            ),
          options:
            Protox.Field.new!(
              tag: 8,
              label: :none,
              name: :options,
              kind: {:scalar, nil},
              type: {:message, Protox.Google.Protobuf.FieldOptions}
            ),
          proto3_optional:
            Protox.Field.new!(
              tag: 17,
              label: :none,
              name: :proto3_optional,
              kind: {:scalar, false},
              type: :bool
            )
        }
      },
      Protox.Google.Protobuf.FileOptions => %Protox.Message{
        name: Protox.Google.Protobuf.FileOptions,
        syntax: :proto2,
        fields: %{
          java_package:
            Protox.Field.new!(
              kind: {:scalar, ""},
              label: :optional,
              name: :java_package,
              tag: 1,
              type: :string
            ),
          java_outer_classname:
            Protox.Field.new!(
              kind: {:scalar, ""},
              label: :optional,
              name: :java_outer_classname,
              tag: 8,
              type: :string
            ),
          optimize_for:
            Protox.Field.new!(
              kind: {:scalar, :SPEED},
              label: :optional,
              name: :optimize_for,
              tag: 9,
              type: {:enum, Protox.Google.Protobuf.FileOptions.OptimizeMode}
            ),
          java_multiple_files:
            Protox.Field.new!(
              kind: {:scalar, false},
              label: :optional,
              name: :java_multiple_files,
              tag: 10,
              type: :bool
            ),
          go_package:
            Protox.Field.new!(
              kind: {:scalar, ""},
              label: :optional,
              name: :go_package,
              tag: 11,
              type: :string
            ),
          cc_generic_services:
            Protox.Field.new!(
              kind: {:scalar, false},
              label: :optional,
              name: :cc_generic_services,
              tag: 16,
              type: :bool
            ),
          java_generic_services:
            Protox.Field.new!(
              kind: {:scalar, false},
              label: :optional,
              name: :java_generic_services,
              tag: 17,
              type: :bool
            ),
          py_generic_services:
            Protox.Field.new!(
              kind: {:scalar, false},
              label: :optional,
              name: :py_generic_services,
              tag: 18,
              type: :bool
            ),
          java_generate_equals_and_hash:
            Protox.Field.new!(
              kind: {:scalar, false},
              label: :optional,
              name: :java_generate_equals_and_hash,
              tag: 20,
              type: :bool
            ),
          deprecated:
            Protox.Field.new!(
              kind: {:scalar, false},
              label: :optional,
              name: :deprecated,
              tag: 23,
              type: :bool
            ),
          java_string_check_utf8:
            Protox.Field.new!(
              kind: {:scalar, false},
              label: :optional,
              name: :java_string_check_utf8,
              tag: 27,
              type: :bool
            ),
          cc_enable_arenas:
            Protox.Field.new!(
              kind: {:scalar, true},
              label: :optional,
              name: :cc_enable_arenas,
              tag: 31,
              type: :bool
            ),
          objc_class_prefix:
            Protox.Field.new!(
              kind: {:scalar, ""},
              label: :optional,
              name: :objc_class_prefix,
              tag: 36,
              type: :string
            ),
          csharp_namespace:
            Protox.Field.new!(
              kind: {:scalar, ""},
              label: :optional,
              name: :csharp_namespace,
              tag: 37,
              type: :string
            ),
          swift_prefix:
            Protox.Field.new!(
              kind: {:scalar, ""},
              label: :optional,
              name: :swift_prefix,
              tag: 39,
              type: :string
            ),
          php_class_prefix:
            Protox.Field.new!(
              kind: {:scalar, ""},
              label: :optional,
              name: :php_class_prefix,
              tag: 40,
              type: :string
            ),
          php_namespace:
            Protox.Field.new!(
              kind: {:scalar, ""},
              label: :optional,
              name: :php_namespace,
              tag: 41,
              type: :string
            ),
          php_generic_services:
            Protox.Field.new!(
              kind: {:scalar, false},
              label: :optional,
              name: :php_generic_services,
              tag: 42,
              type: :bool
            ),
          php_metadata_namespace:
            Protox.Field.new!(
              kind: {:scalar, ""},
              label: :optional,
              name: :php_metadata_namespace,
              tag: 44,
              type: :string
            ),
          ruby_package:
            Protox.Field.new!(
              kind: {:scalar, ""},
              label: :optional,
              name: :ruby_package,
              tag: 45,
              type: :string
            ),
          uninterpreted_option:
            Protox.Field.new!(
              kind: :unpacked,
              label: :repeated,
              name: :uninterpreted_option,
              tag: 999,
              type: {:message, Protox.Google.Protobuf.UninterpretedOption}
            )
        }
      },
      Protox.Google.Protobuf.UninterpretedOption => %Protox.Message{
        name: Protox.Google.Protobuf.UninterpretedOption,
        syntax: :proto2,
        fields: %{
          name:
            Protox.Field.new!(
              tag: 2,
              label: :repeated,
              name: :name,
              kind: :unpacked,
              type: {:message, Protox.Google.Protobuf.UninterpretedOption.NamePart}
            ),
          identifier_value:
            Protox.Field.new!(
              tag: 3,
              label: :none,
              name: :identifier_value,
              kind: {:scalar, nil},
              type: :string
            ),
          positive_int_value:
            Protox.Field.new!(
              tag: 4,
              label: :none,
              name: :positive_int_value,
              kind: {:scalar, nil},
              type: :uint64
            ),
          negative_int_value:
            Protox.Field.new!(
              tag: 5,
              label: :none,
              name: :negative_int_value,
              kind: {:scalar, nil},
              type: :int64
            ),
          double_value:
            Protox.Field.new!(
              tag: 6,
              label: :none,
              name: :double_value,
              kind: {:scalar, nil},
              type: :double
            ),
          string_value:
            Protox.Field.new!(
              tag: 7,
              label: :none,
              name: :string_value,
              kind: {:scalar, nil},
              type: :bytes
            ),
          aggregate_value:
            Protox.Field.new!(
              tag: 8,
              label: :none,
              name: :aggregate_value,
              kind: {:scalar, nil},
              type: :string
            )
        }
      },
      Protox.Google.Protobuf.UninterpretedOption.NamePart => %Protox.Message{
        name: Protox.Google.Protobuf.UninterpretedOption.NamePart,
        syntax: :proto2,
        fields: %{
          name_part:
            Protox.Field.new!(
              tag: 1,
              label: :none,
              name: :name_part,
              kind: {:scalar, nil},
              type: :string
            ),
          is_extension:
            Protox.Field.new!(
              tag: 2,
              label: :none,
              name: :is_extension,
              kind: {:scalar, nil},
              type: :bool
            )
        }
      },
      Protox.Google.Protobuf.OneofDescriptorProto => %Protox.Message{
        name: Protox.Google.Protobuf.OneofDescriptorProto,
        syntax: :proto3,
        fields: %{
          # Ignored: 2
          name:
            Protox.Field.new!(
              tag: 1,
              label: :none,
              name: :name,
              kind: {:scalar, nil},
              type: :string
            )
        }
      },
      Protox.Google.Protobuf.EnumDescriptorProto => %Protox.Message{
        name: Protox.Google.Protobuf.EnumDescriptorProto,
        syntax: :proto3,
        fields: %{
          # Ignored: 3
          name:
            Protox.Field.new!(
              tag: 1,
              label: :none,
              name: :name,
              kind: {:scalar, nil},
              type: :string
            ),
          value:
            Protox.Field.new!(
              tag: 2,
              label: :repeated,
              name: :value,
              kind: :unpacked,
              type: {:message, Protox.Google.Protobuf.EnumValueDescriptorProto}
            )
        }
      },
      Protox.Google.Protobuf.EnumValueDescriptorProto => %Protox.Message{
        name: Protox.Google.Protobuf.EnumValueDescriptorProto,
        syntax: :proto3,
        fields: %{
          # Ignored: 3
          name:
            Protox.Field.new!(
              tag: 1,
              label: :none,
              name: :name,
              kind: {:scalar, nil},
              type: :string
            ),
          number:
            Protox.Field.new!(
              tag: 2,
              label: :none,
              name: :number,
              kind: {:scalar, nil},
              type: :int32
            )
        }
      },
      # ServiceDescriptorProto ignored
      # MethodDescriptorProto ignored
      Protox.Google.Protobuf.MessageOptions => %Protox.Message{
        name: Protox.Google.Protobuf.MessageOptions,
        syntax: :proto3,
        fields: %{
          # 1, 2, 999 ignored
          deprecated:
            Protox.Field.new!(
              tag: 3,
              label: :none,
              name: :deprecated,
              kind: {:scalar, false},
              type: :bool
            ),
          map_entry:
            Protox.Field.new!(
              tag: 7,
              label: :none,
              name: :map_entry,
              kind: {:scalar, false},
              type: :bool
            )
        }
      },
      Protox.Google.Protobuf.FieldOptions => %Protox.Message{
        name: Protox.Google.Protobuf.FieldOptions,
        syntax: :proto3,
        fields: %{
          # 1, 6, 5, 10, 999 ignored
          packed:
            Protox.Field.new!(
              tag: 2,
              label: :none,
              name: :packed,
              kind: {:scalar, nil},
              type: :bool
            ),
          deprecated:
            Protox.Field.new!(
              tag: 3,
              label: :none,
              name: :deprecated,
              kind: {:scalar, false},
              type: :bool
            )
        }
      }
      # OneofOptions ignored
      # EnumOptions ignored
      # EnumValueOptions ignored
      # ServiceOptions ignored
      # MethodOptions ignored
      # SourceCodeInfo ignored
      # GeneratedCodeInfo ignored
    }
end
