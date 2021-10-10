defmodule Google.Protobuf do
  @moduledoc false

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
