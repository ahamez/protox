defmodule Protox.RequiredFieldsError do
  @moduledoc """
  This error is thrown when encoding or decoding a Protobuf 2 message
  with unset required fields (that is, that have the value `nil`).
  """

  defexception message: "Some required fields are not set",
               missing_fields: []

  def new(missing_fields) do
    %__MODULE__{
      message: "Some required fields are not set: #{inspect(missing_fields)}",
      missing_fields: missing_fields
    }
  end
end

defmodule Protox.IllegalTagError do
  @moduledoc """
  This error is thrown when decoding data with a field which tag is 0.
  """

  defexception message: "Field with illegal tag 0"
end

defmodule Protox.DecodingError do
  @moduledoc """
  This error is thrown when a data could not be decoded.
  """

  defexception message: "Could not decode data",
               binary: <<>>,
               reason: nil

  def new(reason, binary) do
    %__MODULE__{
      message: "Could not decode data #{inspect(binary)}",
      binary: binary,
      reason: reason
    }
  end
end
