defmodule Sub do

  defstruct a: 0,
            b: "",
            c: 0,
            d: 0,
            e: 0,
            f: 0,
            g: [],
            h: [],
            i: [],
            j: [],
            k: 0,
            l: 0,
            m: <<>>,
            z: 0


  @spec encode(struct) :: binary
  def encode(msg = %__MODULE__{}) do
    Protox.Encode.encode(msg)
  end


  @spec decode(binary) :: struct
  def decode(bytes) do
    Protox.Decode.decode(bytes, __MODULE__.defs())
  end


  def defs() do
    %Protox.Message{
      name: __MODULE__,
      fields: %{
        1 => %Protox.Field{name: :a, kind: :normal, type: :int32},
        2 => %Protox.Field{name: :b, kind: :normal, type: :string},
        6 => %Protox.Field{name: :c, kind: :normal, type: :int64},
        7 => %Protox.Field{name: :d, kind: :normal, type: :uint32},
        8 => %Protox.Field{name: :e, kind: :normal, type: :uint64},
        9 => %Protox.Field{name: :f, kind: :normal, type: :sint64},
        13 => %Protox.Field{name: :g, kind: {:repeated, :packed}, type: :fixed64},
        14 => %Protox.Field{name: :h, kind: {:repeated, :packed}, type: :sfixed32},
        15 => %Protox.Field{name: :i, kind: {:repeated, :packed}, type: :double},
        16 => %Protox.Field{name: :j, kind: {:repeated, :unpacked}, type: :int32},
        17 => %Protox.Field{name: :k, kind: :normal, type: :fixed32},
        18 => %Protox.Field{name: :l, kind: :normal, type: :sfixed64},
        19 => %Protox.Field{name: :m, kind: :normal, type: :bytes},
        10001 => %Protox.Field{name: :z, kind: :normal, type: :sint32},
      },
      # Ordered by tag value.
      tags: [
        1,
        2,
        6,
        7,
        8,
        9,
        13,
        14,
        15,
        16,
        17,
        18,
        19,
        10001,
      ]
    }
  end

end


#------------------------------------------------------------------------------------------------#

defmodule Msg do

  defstruct d: :FOO,
            e: false,
            f: nil,
            g: [],
            h: 0.0,
            i: [],
            j: [],
            k: %{},
            l: %{},
            m: nil


  @spec encode(struct) :: binary
  def encode(msg = %__MODULE__{}) do
    Protox.Encode.encode(msg)
  end


  @spec decode(binary) :: struct
  def decode(bytes) do
    Protox.Decode.decode(bytes, __MODULE__.defs())
  end


  def defs() do
    %Protox.Message{
      name: __MODULE__,
      fields: %{
        1 => %Protox.Field{name: :d, kind: :normal, type: %Protox.Enumeration{
                members: %{0 => :FOO, 1 => :BAR},
                values: %{FOO: 0, BAR: 1},
              }
            },
        2 => %Protox.Field{name: :e, kind: :normal, type: :bool},
        3 => %Protox.Field{name: :f, kind: :normal, type: Sub.defs()},
        4 => %Protox.Field{name: :g, kind: {:repeated, :packed}, type: :int32},
        5 => %Protox.Field{name: :h, kind: :normal, type: :double},
        6 => %Protox.Field{name: :i, kind: {:repeated, :packed}, type: :float},
        7 => %Protox.Field{name: :j, kind: {:repeated, :unpacked}, type: Sub.defs()},
        8 => %Protox.Field{name: :k, kind: :map, type: {:int32, :string}},
        9 => %Protox.Field{name: :l, kind: :map, type: {:string, :double}},
        10 => %Protox.Field{name: :n, kind: {:oneof, :m}, type: :string},
        11 => %Protox.Field{name: :o, kind: {:oneof, :m}, type: Sub.defs()},
      },
      # Ordered by tag value.
      tags: [
        1,
        2,
        3,
        4,
        5,
        6,
        7,
        8,
        9,
        10,
        11,
      ],
    }
  end
end

#-------------------------------------------------------------------------------------------------#

defmodule Upper do

  defstruct msg: nil,
            msg_map: %{}


  @spec encode(struct) :: binary
  def encode(msg = %__MODULE__{}) do
    Protox.Encode.encode(msg)
  end


  @spec encode(binary) :: struct
  def decode(bytes) do
    Protox.Decode.decode(bytes, __MODULE__.defs())
  end


  def defs() do
    %Protox.Message{
      name: __MODULE__,
      fields: %{
        1 => %Protox.Field{name: :msg, kind: :normal, type: Msg.defs()},
        2 => %Protox.Field{name: :msg_map, kind: :map, type: {:string, Msg.defs()}},
      },
      # Ordered by tag value.
      tags: [
        1,
        2,
      ]
    }
  end

end

#-------------------------------------------------------------------------------------------------#
