defmodule Protox.DefsTest do
  use ExUnit.Case

  @defs [
    {8, nil, :msg_k, :map, {:int32, :string}},
    {9, nil, :msg_l, :map, {:string, :double}},
    {27, :repeated, :msg_a, :packed, :sint64},
    {28, :repeated, :msg_b, :packed, :fixed32},
    {29, :repeated, :msg_c, :packed, :sfixed64},
    {1, :optional, :msg_d, {:default, :FOO}, {:enum, E}},
    {2, :optional, :msg_e, {:default, false}, :bool},
    {3, :optional, :msg_f, {:default, nil}, {:message, Sub}},
    {4, :repeated, :msg_g, :packed, :int32},
    {5, :optional, :msg_h, {:default, 0.0}, :double},
    {6, :repeated, :msg_i, :packed, :float},
    {7, :repeated, :msg_j, :unpacked, {:message, Sub}},
    {10, :optional, :msg_n, {:oneof, :msg_m}, :string},
    {11, :optional, :msg_o, {:oneof, :msg_m}, {:message, Sub}},
    {12, nil, :msg_p, :map, {:int32, {:enum, E}}},
    {13, :optional, :msg_q, {:default, nil}, {:message, Protobuf2}},
    {118, :optional, :msg_oneof_double, {:oneof, :msg_oneof_field}, :double}
  ]

  test "split_oneofs" do
    {oneofs, fields} = Protox.Defs.split_oneofs(@defs)

    assert oneofs == [
             msg_m: [
               {10, :optional, :msg_n, {:oneof, :msg_m}, :string},
               {11, :optional, :msg_o, {:oneof, :msg_m}, {:message, Sub}}
             ],
             msg_oneof_field: [
               {118, :optional, :msg_oneof_double, {:oneof, :msg_oneof_field}, :double}
             ]
           ]

    assert fields == [
             {8, nil, :msg_k, :map, {:int32, :string}},
             {9, nil, :msg_l, :map, {:string, :double}},
             {27, :repeated, :msg_a, :packed, :sint64},
             {28, :repeated, :msg_b, :packed, :fixed32},
             {29, :repeated, :msg_c, :packed, :sfixed64},
             {1, :optional, :msg_d, {:default, :FOO}, {:enum, E}},
             {2, :optional, :msg_e, {:default, false}, :bool},
             {3, :optional, :msg_f, {:default, nil}, {:message, Sub}},
             {4, :repeated, :msg_g, :packed, :int32},
             {5, :optional, :msg_h, {:default, 0.0}, :double},
             {6, :repeated, :msg_i, :packed, :float},
             {7, :repeated, :msg_j, :unpacked, {:message, Sub}},
             {12, nil, :msg_p, :map, {:int32, {:enum, E}}},
             {13, :optional, :msg_q, {:default, nil}, {:message, Protobuf2}}
           ]
  end

  test "split_maps" do
    {maps, fields} = Protox.Defs.split_maps(@defs)

    assert maps == [
             {8, nil, :msg_k, :map, {:int32, :string}},
             {9, nil, :msg_l, :map, {:string, :double}},
             {12, nil, :msg_p, :map, {:int32, {:enum, E}}}
           ]

    assert fields == [
             {27, :repeated, :msg_a, :packed, :sint64},
             {28, :repeated, :msg_b, :packed, :fixed32},
             {29, :repeated, :msg_c, :packed, :sfixed64},
             {1, :optional, :msg_d, {:default, :FOO}, {:enum, E}},
             {2, :optional, :msg_e, {:default, false}, :bool},
             {3, :optional, :msg_f, {:default, nil}, {:message, Sub}},
             {4, :repeated, :msg_g, :packed, :int32},
             {5, :optional, :msg_h, {:default, 0.0}, :double},
             {6, :repeated, :msg_i, :packed, :float},
             {7, :repeated, :msg_j, :unpacked, {:message, Sub}},
             {10, :optional, :msg_n, {:oneof, :msg_m}, :string},
             {11, :optional, :msg_o, {:oneof, :msg_m}, {:message, Sub}},
             {13, :optional, :msg_q, {:default, nil}, {:message, Protobuf2}},
             {118, :optional, :msg_oneof_double, {:oneof, :msg_oneof_field}, :double}
           ]
  end
end
