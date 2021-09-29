defmodule Google.Protobuf do
  @moduledoc false

  use Protox,
    schema: """
    import "google/protobuf/any.proto";
    import "google/protobuf/duration.proto";
    import "google/protobuf/field_mask.proto";
    import "google/protobuf/struct.proto";
    import "google/protobuf/timestamp.proto";
    import "google/protobuf/wrappers.proto";
    """
end
