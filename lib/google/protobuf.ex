defmodule Google.Protobuf do
  @moduledoc false

  # To avoid the compilation of well-known types each time a file includes those,
  # we force their compilation here (__compile_well_known_types default to false,
  # thus other usages of the Protox macro won't generate modules of well-known types
  # that would have to be compiled).
  use Protox,
    files: [
      "./lib/google/any.proto",
      "./lib/google/duration.proto",
      "./lib/google/empty.proto",
      "./lib/google/field_mask.proto",
      "./lib/google/struct.proto",
      "./lib/google/timestamp.proto",
      "./lib/google/wrappers.proto"
    ],
    __compile_well_known_types: true

  def well_known_types() do
    [
      Google.Protobuf.Any,
      Google.Protobuf.BoolValue,
      Google.Protobuf.BytesValue,
      Google.Protobuf.DoubleValue,
      Google.Protobuf.Duration,
      Google.Protobuf.Empty,
      Google.Protobuf.FieldMask,
      Google.Protobuf.FloatValue,
      Google.Protobuf.Int32Value,
      Google.Protobuf.Int64Value,
      Google.Protobuf.ListValue,
      Google.Protobuf.NullValue,
      Google.Protobuf.StringValue,
      Google.Protobuf.Struct,
      Google.Protobuf.Timestamp,
      Google.Protobuf.UInt32Value,
      Google.Protobuf.UInt64Value,
      Google.Protobuf.Value
    ]
  end
end
