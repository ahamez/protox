defmodule Defs do
  use Protox.Define,
    enums: [
      {
        E,
        [
          {0, :FOO},
          {1, :BAZ},
          {1, :BAR},
          {-1, :NEG}
        ]
      },
      {
        F,
        [
          {1, :ONE},
          {2, :TWO}
        ]
      }
    ],
    messages: [
      {
        Protobuf2,
        :proto2,
        [
          Protox.Field.new(
            tag: 1,
            label: :optional,
            name: :a,
            kind: {:default, 0},
            type: :uint64
          ),
          Protox.Field.new(
            tag: 25,
            label: :optional,
            name: :s,
            kind: {:default, :TWO},
            type: {:enum, F}
          ),
          Protox.Field.new(
            tag: 26,
            label: :optional,
            name: :t,
            kind: {:default, :ONE},
            type: {:enum, F}
          )
        ]
      },
      {
        Sub,
        :proto3,
        [
          # tag     label    name     kind           type
          Protox.Field.new(tag: 1, label: :optional, name: :a, kind: {:default, 0}, type: :int32),
          Protox.Field.new(
            tag: 2,
            label: :optional,
            name: :b,
            kind: {:default, ""},
            type: :string
          ),
          Protox.Field.new(tag: 6, label: :optional, name: :c, kind: {:default, 0}, type: :int64),
          Protox.Field.new(
            tag: 7,
            label: :optional,
            name: :d,
            kind: {:default, 0},
            type: :uint32
          ),
          Protox.Field.new(
            tag: 8,
            label: :optional,
            name: :e,
            kind: {:default, 0},
            type: :uint64
          ),
          Protox.Field.new(
            tag: 9,
            label: :optional,
            name: :f,
            kind: {:default, 0},
            type: :sint64
          ),
          Protox.Field.new(tag: 13, label: :repeated, name: :g, kind: :packed, type: :fixed64),
          Protox.Field.new(tag: 14, label: :repeated, name: :h, kind: :packed, type: :sfixed32),
          Protox.Field.new(tag: 15, label: :repeated, name: :i, kind: :packed, type: :double),
          Protox.Field.new(tag: 16, label: :repeated, name: :j, kind: :unpacked, type: :int32),
          Protox.Field.new(
            tag: 17,
            label: :optional,
            name: :k,
            kind: {:default, 0},
            type: :fixed32
          ),
          Protox.Field.new(
            tag: 18,
            label: :optional,
            name: :l,
            kind: {:default, 0},
            type: :sfixed64
          ),
          Protox.Field.new(
            tag: 19,
            label: :optional,
            name: :m,
            kind: {:default, <<>>},
            type: :bytes
          ),
          Protox.Field.new(tag: 20, label: :repeated, name: :n, kind: :packed, type: :bool),
          Protox.Field.new(tag: 21, label: :repeated, name: :o, kind: :packed, type: {:enum, E}),
          Protox.Field.new(tag: 22, label: :repeated, name: :p, kind: :unpacked, type: :bool),
          Protox.Field.new(
            tag: 23,
            label: :repeated,
            name: :q,
            kind: :unpacked,
            type: {:enum, E}
          ),
          Protox.Field.new(
            tag: 24,
            label: :optional,
            name: :r,
            kind: {:default, :FOO},
            type: {:enum, E}
          ),
          Protox.Field.new(tag: 27, label: :repeated, name: :u, kind: :packed, type: :uint32),
          Protox.Field.new(tag: 28, label: :repeated, name: :w, kind: :packed, type: :sint32),
          Protox.Field.new(tag: 29, label: :repeated, name: :x, kind: :packed, type: :int64),
          Protox.Field.new(tag: 30, label: :repeated, name: :y, kind: :packed, type: :uint64),
          Protox.Field.new(
            tag: 10_001,
            label: :optional,
            name: :z,
            kind: {:default, 0},
            type: :sint32
          ),
          Protox.Field.new(
            tag: 10_002,
            label: :optional,
            name: :zz,
            kind: {:default, 0},
            type: :sint64
          ),
          Protox.Field.new(
            tag: 12_345,
            name: :map1,
            kind: :map,
            type: {:sfixed64, :bytes}
          ),
          Protox.Field.new(
            tag: 12_346,
            name: :map2,
            kind: :map,
            type: {:sfixed64, :bytes}
          )
        ]
      },
      {
        Msg,
        :proto3,
        [
          Protox.Field.new(tag: 27, label: :repeated, name: :msg_a, kind: :packed, type: :sint64),
          Protox.Field.new(
            tag: 28,
            label: :repeated,
            name: :msg_b,
            kind: :packed,
            type: :fixed32
          ),
          Protox.Field.new(
            tag: 29,
            label: :repeated,
            name: :msg_c,
            kind: :packed,
            type: :sfixed64
          ),
          Protox.Field.new(
            tag: 1,
            label: :optional,
            name: :msg_d,
            kind: {:default, :FOO},
            type: {:enum, E}
          ),
          Protox.Field.new(
            tag: 2,
            label: :optional,
            name: :msg_e,
            kind: {:default, false},
            type: :bool
          ),
          Protox.Field.new(
            tag: 3,
            label: :optional,
            name: :msg_f,
            kind: {:default, nil},
            type: {:message, Sub}
          ),
          Protox.Field.new(tag: 4, label: :repeated, name: :msg_g, kind: :packed, type: :int32),
          Protox.Field.new(
            tag: 5,
            label: :optional,
            name: :msg_h,
            kind: {:default, 0.0},
            type: :double
          ),
          Protox.Field.new(tag: 6, label: :repeated, name: :msg_i, kind: :packed, type: :float),
          Protox.Field.new(
            tag: 7,
            label: :repeated,
            name: :msg_j,
            kind: :unpacked,
            type: {:message, Sub}
          ),
          Protox.Field.new(tag: 8, name: :msg_k, kind: :map, type: {:int32, :string}),
          Protox.Field.new(
            tag: 9,
            name: :msg_l,
            kind: :map,
            type: {:string, :double}
          ),
          Protox.Field.new(
            tag: 10,
            label: :optional,
            name: :msg_n,
            kind: {:oneof, :msg_m},
            type: :string
          ),
          Protox.Field.new(
            tag: 11,
            label: :optional,
            name: :msg_o,
            kind: {:oneof, :msg_m},
            type: {:message, Sub}
          ),
          Protox.Field.new(
            tag: 12,
            name: :msg_p,
            kind: :map,
            type: {:int32, {:enum, E}}
          ),
          Protox.Field.new(
            tag: 13,
            label: :optional,
            name: :msg_q,
            kind: {:default, nil},
            type: {:message, Protobuf2}
          ),
          Protox.Field.new(
            tag: 118,
            label: :optional,
            name: :msg_oneof_double,
            kind: {:oneof, :msg_oneof_field},
            type: :double
          )
        ]
      },
      {
        Upper,
        :proto3,
        [
          Protox.Field.new(
            tag: 1,
            label: :optional,
            name: :msg,
            kind: {:default, nil},
            type: {:message, Msg}
          ),
          Protox.Field.new(
            tag: 2,
            name: :msg_map,
            kind: :map,
            type: {:string, {:message, Msg}}
          ),
          Protox.Field.new(
            tag: 3,
            label: :optional,
            name: :empty,
            kind: {:default, nil},
            type: {:message, Empty}
          ),
          Protox.Field.new(
            tag: 4,
            label: :optional,
            name: :req,
            kind: {:default, nil},
            type: {:message, Required}
          )
        ]
      },
      {
        Empty,
        :proto3,
        []
      },
      {
        Required,
        :proto2,
        [
          Protox.Field.new(tag: 1, label: :required, name: :a, kind: {:default, 0}, type: :int32),
          Protox.Field.new(tag: 2, label: :optional, name: :b, kind: {:default, 0}, type: :int32)
        ]
      },
      {
        NoNameClash,
        :proto3,
        [
          Protox.Field.new(
            tag: 1,
            label: :optional,
            name: :__uf__,
            kind: {:default, 0},
            type: :int32
          )
        ]
      },
      {
        NestedMessage,
        :proto3,
        [
          Protox.Field.new(tag: 1, label: :none, name: :a, kind: {:default, 0}, type: :int32),
          Protox.Field.new(
            tag: 2,
            label: :none,
            name: :corecursive,
            kind: {:default, nil},
            type: {:message, TestAllTypesProto3}
          )
        ]
      },
      {
        TestAllTypesProto3,
        :proto3,
        [
          Protox.Field.new(
            tag: 112,
            label: :none,
            name: :oneof_nested_message,
            kind: {:oneof, :oneof_field},
            type: {:message, NestedMessage}
          )
        ]
      },
      {
        FloatPrecision,
        :proto3,
        [
          Protox.Field.new(
            tag: 1,
            label: :optional,
            name: :a,
            kind: {:default, 0.0},
            type: :double
          ),
          Protox.Field.new(
            tag: 2,
            label: :optional,
            name: :b,
            kind: {:default, 0.0},
            type: :float
          )
        ]
      }
    ]
end
