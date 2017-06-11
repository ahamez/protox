defmodule Defs do

  use Protox.Define,
    enums: [
      {
        E,
        [
          {0,  :FOO},
          {1,  :BAZ},
          {1,  :BAR},
          {-1, :NEG},
        ]
      },
      {
        F,
        [
          {1, :ONE},
          {2, :TWO},
        ]
      }
    ],
    messages: [
    {
      Protobuf2,
      [
        {25    , :optional, :s, {:default, :TWO}, {:enum, F}},
        {26    , :optional, :t, {:default, nil} , {:enum, F}},
      ]
    },
    {
      Sub,
      [
        #tag     label    name     kind           type
        {1     , :optional, :a, {:default, 0}   , :int32},
        {2     , :optional, :b, {:default, ""}  , :string},
        {6     , :optional, :c, {:default, 0}   , :int64},
        {7     , :optional, :d, {:default, 0}   , :uint32},
        {8     , :optional, :e, {:default, 0}   , :uint64},
        {9     , :optional, :f, {:default, 0}   , :sint64},
        {13    , :repeated, :g, :packed         , :fixed64},
        {14    , :repeated, :h, :packed         , :sfixed32},
        {15    , :repeated, :i, :packed         , :double},
        {16    , :repeated, :j, :unpacked       , :int32},
        {17    , :optional, :k, {:default, 0}   , :fixed32},
        {18    , :optional, :l, {:default, 0}   , :sfixed64},
        {19    , :optional, :m, {:default, <<>>}, :bytes},
        {20    , :repeated, :n, :packed         , :bool},
        {21    , :repeated, :o, :packed         , {:enum, E}},
        {22    , :repeated, :p, :unpacked       , :bool},
        {23    , :repeated, :q, :unpacked       , {:enum, E}},
        {24    , :optional, :r, {:default, :FOO}, {:enum, E}},
        {27    , :repeated, :u, :packed         , :uint32},
        {28    , :repeated, :w, :packed         , :sint32},
        {29    , :repeated, :x, :packed         , :int64},
        {30    , :repeated, :y, :packed         , :uint64},
        {10_001, :optional, :z, {:default, 0}   , :sint32},
      ]
    },
    {
      Msg,
      [
        {27 , :repeated, :a           , :packed               , :sint64},
        {28 , :repeated, :b           , :packed               , :fixed32},
        {29 , :repeated, :c           , :packed               , :sfixed64},
        {1  , :optional, :d           , {:default, :FOO}      , {:enum, E}},
        {2  , :optional, :e           , {:default, false}     , :bool},
        {3  , :optional, :f           , {:default, nil}       , {:message, Sub}},
        {4  , :repeated, :g           , :packed               , :int32},
        {5  , :optional, :h           , {:default, 0.0}       , :double},
        {6  , :repeated, :i           , :packed               , :float},
        {7  , :repeated, :j           , :unpacked             , {:message, Sub}},
        {8  , nil      , :k           , :map                  , {:int32, :string}},
        {9  , nil      , :l           , :map                  , {:string, :double}},
        {10 , :optional, :n           , {:oneof, :m}          , :string},
        {11 , :optional, :o           , {:oneof, :m}          , {:message, Sub}},
        {12 , nil      , :p           , :map                  , {:int32, {:enum, E}}},
        {13 , :optional, :q           , {:default, nil}       , {:message, Protobuf2}},
        {118, :optional, :oneof_double, {:oneof, :oneof_field}, :double},
      ]
    },
    {
      Upper,
      [
        {1, :optional, :msg    , {:default, nil}, {:message, Msg}},
        {2, nil      , :msg_map, :map           , {:string, {:message, Msg}}},
        {3, :optional, :empty  , {:default, nil}, {:message, Empty}}
      ]
    },
    {
      Empty,
      []
    },
    {
      Required,
      [
        {1, :required, :a, {:default, 0}, :int32}
      ]
    },
    {
      NoNameClash,
      [
        {1, :optional, :__uf__, {:default, 0}, :int32}
      ]
    }
  ]

end
