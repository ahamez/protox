defmodule Defs do

  use Protox.Define,
    enums: [
      {
        E,
        [{0, :FOO}, {1, :BAR}]
      }
    ],
    messages: [
    {
      Sub,
      [
        {1 , :optional, :a, {:normal, 0}, :int32},
        {2 , :optional, :b, {:normal, ""}, :string},
        {6 , :optional, :c, {:normal, 0}, :int64},
        {7 , :optional, :d, {:normal, 0}, :uint32},
        {8 , :optional, :e, {:normal, 0}, :uint64},
        {9 , :optional, :f, {:normal, 0}, :sint64},
        {13, :optional, :g, {:repeated, :packed}, :fixed64},
        {14, :optional, :h, {:repeated, :packed}, :sfixed32},
        {15, :optional, :i, {:repeated, :packed}, :double},
        {16, :optional, :j, {:repeated, :unpacked}, :int32},
        {17, :optional, :k, {:normal, 0}, :fixed32},
        {18, :optional, :l, {:normal, 0}, :sfixed64},
        {19, :optional, :m, {:normal, <<>>}, :bytes},
        {20, :optional, :n, {:repeated, :packed}, :bool},
        {21, :optional, :o, {:repeated, :packed}, {:enum, E}},
        {22, :optional, :p, {:repeated, :unpacked}, :bool},
        {23, :optional, :q, {:repeated, :unpacked}, {:enum, E}},
        {24 , :optional, :r, {:normal, :FOO}, {:enum, E}},
        {10001, :required, :z, {:normal, 0}, :sint32},
      ]
    },
    {
      Msg,
      [
        {1 , :optional, :d, {:normal, :FOO}, {:enum, E}},
        {2 , :optional, :e, {:normal, false}, :bool},
        {3 , :optional, :f, {:normal, nil}, {:message, Sub}},
        {4 , :optional, :g, {:repeated, :packed}, :int32},
        {5 , :optional, :h, {:normal, 0}, :double},
        {6 , :optional, :i, {:repeated, :packed}, :float},
        {7 , :optional, :j, {:repeated, :unpacked}, {:message, Sub}},
        {8 , :optional, :k, :map, {:int32, :string}},
        {9 , :optional, :l, :map, {:string, :double}},
        {10, :optional, :n, {:oneof, :m}, :string},
        {11, :optional, :o, {:oneof, :m}, {:message, Sub}},
        {12, :optional, :p, :map, {:int32, {:enum, E}}},
      ]
    },
    {
      Upper,
      [
        {1, :optional, :msg, {:normal, nil}, {:message, Msg}},
        {2, :optional, :msg_map, :map, {:string, {:message, Msg}}},
      ]
    },
    {
      Empty,
      []
    }
  ]

end

#-------------------------------------------------------------------------------------------------#
