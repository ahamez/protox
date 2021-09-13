defmodule Protox.RequiredFieldsError do
  @moduledoc """
  This error is thrown when encoding or decoding a Protobuf 2 message
  with unset required fields (that is, that have the value `nil`).
  """

  defexception message: "",
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

  def new() do
    %__MODULE__{}
  end
end

defmodule Protox.InvalidFieldAttribute do
  @moduledoc """
  This error is thrown when a field is constructed with an invalid atribute.
  """

  defexception message: ""

  def new(attribute, expected, got) do
    %__MODULE__{
      message:
        "Field attribute #{attribute} should be in #{inspect(expected)}, got #{inspect(got)}"
    }
  end
end

defmodule Protox.DecodingError do
  @moduledoc """
  This error is thrown when a data could not be decoded.
  """

  defexception message: "",
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
