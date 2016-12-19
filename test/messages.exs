defmodule Defs do

  use Protox.BuildMessage,
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
        {1 , :a, {:normal, 0}, :int32},
        {2 , :b, {:normal, ""}, :string},
        {6 , :c, {:normal, 0}, :int64},
        {7 , :d, {:normal, 0}, :uint32},
        {8 , :e, {:normal, 0}, :uint64},
        {9 , :f, {:normal, 0}, :sint64},
        {13, :g, {:repeated, :packed}, :fixed64},
        {14, :h, {:repeated, :packed}, :sfixed32},
        {15, :i, {:repeated, :packed}, :double},
        {16, :j, {:repeated, :unpacked}, :int32},
        {17, :k, {:normal, 0}, :fixed32},
        {18, :l, {:normal, 0}, :sfixed64},
        {19, :m, {:normal, <<>>}, :bytes},
        {20, :n, {:repeated, :packed}, :bool},
        {21, :o, {:repeated, :packed}, {:enum, E}},
        {22, :p, {:repeated, :unpacked}, :bool},
        {23, :q, {:repeated, :unpacked}, {:enum, E}},
        {24 , :r, {:normal, :FOO}, {:enum, E}},
        {10001, :z, {:normal, 0}, :sint32},
      ]
    },
    {
      Msg,
      [
        {1 , :d, {:normal, :FOO}, {:enum, E}},
        {2 , :e, {:normal, false}, :bool},
        {3 , :f, {:normal, nil}, {:message, Sub}},
        {4 , :g, {:repeated, :packed}, :int32},
        {5 , :h, {:normal, 0}, :double},
        {6 , :i, {:repeated, :packed}, :float},
        {7 , :j, {:repeated, :unpacked}, {:message, Sub}},
        {8 , :k, :map, {:int32, :string}},
        {9 , :l, :map, {:string, :double}},
        {10, :n, {:oneof, :m}, :string},
        {11, :o, {:oneof, :m}, {:message, Sub}},
        {12, :p, :map, {:int32, {:enum, E}}},
      ]
    },
    {
      Upper,
      [
        {1, :msg, {:normal, nil}, {:message, Msg}},
        {2, :msg_map, :map, {:string, {:message, Msg}}},
      ]
    }
  ]

end

#-------------------------------------------------------------------------------------------------#
