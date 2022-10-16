defmodule Protox.DefsTest do
  use ExUnit.Case

  alias Protox.Field

  @defs [
    Field.new!(tag: 8, label: nil, name: :msg_k, kind: :map, type: {:int32, :string}),
    Field.new!(tag: 9, label: nil, name: :msg_l, kind: :map, type: {:string, :double}),
    Field.new!(tag: 27, label: :repeated, name: :msg_a, kind: :packed, type: :sint64),
    Field.new!(tag: 28, label: :repeated, name: :msg_b, kind: :packed, type: :fixed32),
    Field.new!(tag: 29, label: :repeated, name: :msg_c, kind: :packed, type: :sfixed64),
    Field.new!(tag: 1, label: :optional, name: :msg_d, kind: {:scalar, :FOO}, type: {:enum, E}),
    Field.new!(tag: 2, label: :optional, name: :msg_e, kind: {:scalar, false}, type: :bool),
    Field.new!(
      tag: 3,
      label: :optional,
      name: :msg_f,
      kind: {:scalar, nil},
      type: {:message, Sub}
    ),
    Field.new!(tag: 4, label: :repeated, name: :msg_g, kind: :packed, type: :int32),
    Field.new!(tag: 5, label: :optional, name: :msg_h, kind: {:scalar, 0.0}, type: :double),
    Field.new!(tag: 6, label: :repeated, name: :msg_i, kind: :packed, type: :float),
    Field.new!(tag: 7, label: :repeated, name: :msg_j, kind: :unpacked, type: {:message, Sub}),
    Field.new!(tag: 10, label: :optional, name: :msg_n, kind: {:oneof, :msg_m}, type: :string),
    Field.new!(
      tag: 11,
      label: :optional,
      name: :msg_o,
      kind: {:oneof, :msg_m},
      type: {:message, Sub}
    ),
    Field.new!(tag: 12, label: nil, name: :msg_p, kind: :map, type: {:int32, {:enum, E}}),
    Field.new!(
      tag: 13,
      label: :optional,
      name: :msg_q,
      kind: {:scalar, nil},
      type: {:message, Protobuf2}
    ),
    Field.new!(
      tag: 118,
      label: :optional,
      name: :msg_oneof_double,
      kind: {:oneof, :msg_oneof_field},
      type: :double
    )
  ]

  test "split_oneofs" do
    %{oneofs: oneofs_fields, others: other_fields} = Protox.Defs.split_oneofs(@defs)

    assert oneofs_fields == %{
             msg_m: [
               Field.new!(
                 tag: 10,
                 label: :optional,
                 name: :msg_n,
                 kind: {:oneof, :msg_m},
                 type: :string
               ),
               Field.new!(
                 tag: 11,
                 label: :optional,
                 name: :msg_o,
                 kind: {:oneof, :msg_m},
                 type: {:message, Sub}
               )
             ],
             msg_oneof_field: [
               Field.new!(
                 tag: 118,
                 label: :optional,
                 name: :msg_oneof_double,
                 kind: {:oneof, :msg_oneof_field},
                 type: :double
               )
             ]
           }

    other_fields_tags = [8, 9, 27, 28, 29, 1, 2, 3, 4, 5, 6, 7, 12, 13]
    Enum.each(other_fields, fn %Field{} = field -> assert field.tag in other_fields_tags end)
  end

  test "split_maps" do
    {maps_fields, other_fields} = Protox.Defs.split_maps(@defs)

    maps_fields_tags = [8, 9, 12]
    other_fields_tags = [27, 28, 29, 1, 2, 3, 4, 5, 6, 7, 10, 11, 13, 118]

    Enum.each(maps_fields, fn %Field{} = field -> assert field.tag in maps_fields_tags end)
    Enum.each(other_fields, fn %Field{} = field -> assert field.tag in other_fields_tags end)
  end
end
