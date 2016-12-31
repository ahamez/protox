defmodule Protox.Conformance.Defs do

  @moduledoc """
  This module contains definitions from both `conformance.proto` and `test_messages_proto3.proto`,
  which are used by `conformance-test-runner`.

  test_messages_proto3.proto:
  https://raw.githubusercontent.com/google/protobuf/master/src/google/protobuf/test_messages_proto3.proto

  conformance.proto:
  https://raw.githubusercontent.com/google/protobuf/master/conformance/conformance.proto
  """

  use Protox.Define,
    enums: [
      {
        WireFormat,
        [
          {0, :UNSPECIFIED},
          {1, :PROTOBUF},
          {2, :JSON},
        ]
      },
      {
        NestedEnum,
        [
          {0, :FOO},
          {1, :BAR},
          {2, :BAZ},
          {-1, :NEG},
        ]
      },
      {
        ForeignEnum,
        [
          {0, :FOREIGN_FOO},
          {1, :FOREIGN_BAR},
          {2, :FOREIGN_BAZ},
        ]
      },
    ],
    messages: [
      {
        ConformanceRequest,
        [
          {1, :none, :protobuf_payload, {:oneof, :payload}, :bytes},
          {2, :none, :json_payload, {:oneof, :payload}, :string},
          {3, :none, :requested_output_format, {:default, :UNSPECIFIED}, {:enum, WireFormat}},
        ]
      },
      {
        ConformanceResponse,
        [
          {1, :none, :parse_error, {:oneof, :result}, :string},
          {6, :none, :serialize_error, {:oneof, :result}, :string},
          {2, :none, :runtime_error, {:oneof, :result}, :string},
          {3, :none, :protobuf_payload, {:oneof, :result}, :string},
          {4, :none, :json_payload, {:oneof, :result}, :string},
          {5, :none, :skipped, {:oneof, :result}, :string},
        ]
      },
      {
        NestedMessage,
        [
          {1, :none, :a, {:default, 0}, :int32},
          {2, :none, :corecursive, {:default, nil}, {:message, TestAllTypes}},
        ]
      },
      {
        ForeignMessage,
        [
          {1 , :none, :c, {:default, 0}, :int32},
        ]
      },
      {
        TestAllTypes,
        [
          {1 , :none, :optional_int32   , {:default, 0}, :int32},
          {2 , :none, :optional_int64   , {:default, 0}, :int64},
          {3 , :none, :optional_uint32  , {:default, 0}, :uint32},
          {4 , :none, :optional_uint64  , {:default, 0}, :uint64},
          {5 , :none, :optional_sint32  , {:default, 0}, :sint32},
          {6 , :none, :optional_sint64  , {:default, 0}, :sint64},
          {7 , :none, :optional_fixed32 , {:default, 0}, :fixed32},
          {8 , :none, :optional_fixed64 , {:default, 0}, :fixed64},
          {9 , :none, :optional_sfixed32, {:default, 0}, :sfixed32},
          {10, :none, :optional_sfixed64, {:default, 0}, :sfixed64},
          {11, :none, :optional_float   , {:default, 0}, :float},
          {12, :none, :optional_double  , {:default, 0}, :double},
          {13, :none, :optional_bool    , {:default, false}, :bool},
          {14, :none, :optional_string  , {:default, ""}, :string},
          {15, :none, :optional_bytes   , {:default, <<>>}, :bytes},

          {18, :none, :optional_nested_message, {:default, nil}, {:message, NestedMessage}},
          {19, :none, :optional_foreign_message, {:default, nil}, {:message, ForeignMessage}},

          {21, :none, :optional_nested_enum, {:default, :FOO}, {:enum, NestedEnum}},
          {22, :none, :optional_foreign_enum, {:default, :FOREIGN_FOO}, {:enum, ForeignEnum}},

          {24, :none, :optional_string_piece, {:default, ""}, :string},
          {25, :none, :optional_cord, {:default, ""}, :string},

          {27, :none, :recursive_message, {:default, nil}, {:message, TestAllTypes}},

          {31, :repeated, :repeated_int32, :packed, :int32},
          {32, :repeated, :repeated_int64, :packed, :int64},
          {33, :repeated, :repeated_uint32, :packed, :uint32},
          {34, :repeated, :repeated_uint64, :packed, :uint64},
          {35, :repeated, :repeated_sint32, :packed, :sint32},
          {36, :repeated, :repeated_sint64, :packed, :sint64},
          {37, :repeated, :repeated_fixed32, :packed, :fixed32},
          {38, :repeated, :repeated_fixed64, :packed, :fixed64},
          {39, :repeated, :repeated_sfixed32, :packed, :sfixed32},
          {40, :repeated, :repeated_sfixed64, :packed, :sfixed64},
          {41, :repeated, :repeated_float, :packed, :float},
          {42, :repeated, :repeated_double, :packed, :double},
          {43, :repeated, :repeated_bool, :packed, :bool},
          {44, :repeated, :repeated_string, :unpacked, :string},
          {45, :repeated, :repeated_bytes, :unpacked, :bytes},

          {48, :repeated, :repeated_nested_message, :unpacked, {:message, NestedMessage}},
          {49, :repeated, :repeated_foreign_message, :unpacked, {:message, ForeignMessage}},

          {51, :repeated, :repeated_nested_enum, :packed, {:enum, NestedEnum}},
          {52, :repeated, :repeated_foreign_enum, :packed, {:enum, ForeignEnum}},

          {54, :repeated, :repeated_string_piece, :unpacked, :string},
          {55, :repeated, :repeated_cord, :unpacked, :string},

          {56, :none, :map_int32_int32, :map, {:int32, :int32}},
          {57, :none, :map_int64_int64, :map, {:int64, :int64}},
          {58, :none, :map_uint32_uint32, :map, {:uint32, :uint32}},
          {59, :none, :map_uint64_uint64, :map, {:uint64, :uint64}},
          {60, :none, :map_sint32_sint32, :map, {:sint32, :int32}},
          {61, :none, :map_sint64_sint64, :map, {:sint64, :int64}},
          {62, :none, :map_fixed32_fixed32, :map, {:fixed32, :fixed32}},
          {63, :none, :map_fixed64_fixed64, :map, {:fixed64, :fixed64}},
          {64, :none, :map_sfixed32_sfixed32, :map, {:sfixed32, :sfixed32}},
          {65, :none, :map_sfixed64_sfixed64, :map, {:sfixed64, :sfixed64}},
          {66, :none, :map_int32_float, :map, {:int32, :float}},
          {67, :none, :map_int32_double, :map, {:int32, :double}},
          {68, :none, :map_bool_bool, :map, {:bool, :bool}},
          {69, :none, :map_string_string, :map, {:string, :string}},
          {70, :none, :map_string_bytes, :map, {:string, :bytes}},
          {71, :none, :map_string_nested_message, :map, {:string, {:message, NestedMessage}}},
          {72, :none, :map_string_foreign_message, :map, {:string, {:message, ForeignMessage}}},
          {73, :none, :map_string_nested_enum, :map, {:string, {:enum, NestedEnum}}},
          {74, :none, :map_string_foreign_enum, :map, {:string, {:enum, ForeignEnum}}},

          {111, :none, :oneof_uint32, {:oneof, :oneof_field}, :uint32},
          {112, :none, :oneof_nested_message, {:oneof, :oneof_field}, {:message, NestedMessage}},
          {113, :none, :oneof_string, {:oneof, :oneof_field}, :string},
          {114, :none, :oneof_bytes, {:oneof, :oneof_field}, :bytes},
          {115, :none, :oneof_bool, {:oneof, :oneof_field}, :bool},
          {116, :none, :oneof_uint64, {:oneof, :oneof_field}, :uint64},
          {117, :none, :oneof_float, {:oneof, :oneof_field}, :float},
          {118, :none, :oneof_double, {:oneof, :oneof_field}, :double},
          {119, :none, :oneof_enum, {:oneof, :oneof_field}, {:enum, NestedEnum}},

        ]
      }
    ]

# All the following fields from `test_messages_proto3.proto`are not defined on purpose
# as it seems that only the JSON part of the conformance test uses them.
# Furthermore, conformance-test-runner doesn't report any error on these fields.
# However, let's keep them here as a reminder.

#   // Well-known types
#   google.protobuf.BoolValue optional_bool_wrapper = 201;
#   google.protobuf.Int32Value optional_int32_wrapper = 202;
#   google.protobuf.Int64Value optional_int64_wrapper = 203;
#   google.protobuf.UInt32Value optional_uint32_wrapper = 204;
#   google.protobuf.UInt64Value optional_uint64_wrapper = 205;
#   google.protobuf.FloatValue optional_float_wrapper = 206;
#   google.protobuf.DoubleValue optional_double_wrapper = 207;
#   google.protobuf.StringValue optional_string_wrapper = 208;
#   google.protobuf.BytesValue optional_bytes_wrapper = 209;

#   repeated google.protobuf.BoolValue repeated_bool_wrapper = 211;
#   repeated google.protobuf.Int32Value repeated_int32_wrapper = 212;
#   repeated google.protobuf.Int64Value repeated_int64_wrapper = 213;
#   repeated google.protobuf.UInt32Value repeated_uint32_wrapper = 214;
#   repeated google.protobuf.UInt64Value repeated_uint64_wrapper = 215;
#   repeated google.protobuf.FloatValue repeated_float_wrapper = 216;
#   repeated google.protobuf.DoubleValue repeated_double_wrapper = 217;
#   repeated google.protobuf.StringValue repeated_string_wrapper = 218;
#   repeated google.protobuf.BytesValue repeated_bytes_wrapper = 219;

#   google.protobuf.Duration optional_duration = 301;
#   google.protobuf.Timestamp optional_timestamp = 302;
#   google.protobuf.FieldMask optional_field_mask = 303;
#   google.protobuf.Struct optional_struct = 304;
#   google.protobuf.Any optional_any = 305;
#   google.protobuf.Value optional_value = 306;

#   repeated google.protobuf.Duration repeated_duration = 311;
#   repeated google.protobuf.Timestamp repeated_timestamp = 312;
#   repeated google.protobuf.FieldMask repeated_fieldmask = 313;
#   repeated google.protobuf.Struct repeated_struct = 324;
#   repeated google.protobuf.Any repeated_any = 315;
#   repeated google.protobuf.Value repeated_value = 316;

#   // Test field-name-to-JSON-name convention.
#   // (protobuf says names can be any valid C/C++ identifier.)
#   int32 fieldname1 = 401;
#   int32 field_name2 = 402;
#   int32 _field_name3 = 403;
#   int32 field__name4_ = 404;
#   int32 field0name5 = 405;
#   int32 field_0_name6 = 406;
#   int32 fieldName7 = 407;
#   int32 FieldName8 = 408;
#   int32 field_Name9 = 409;
#   int32 Field_Name10 = 410;
#   int32 FIELD_NAME11 = 411;
#   int32 FIELD_name12 = 412;
#   int32 __field_name13 = 413;
#   int32 __Field_name14 = 414;
#   int32 field__name15 = 415;
#   int32 field__Name16 = 416;
#   int32 field_name17__ = 417;
#   int32 Field_name18__ = 418;

end
