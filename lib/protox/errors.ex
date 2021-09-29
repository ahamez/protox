defmodule Protox.DecodingError do
  @moduledoc """
  This error is thrown when a data could not be decoded.
  """

  defexception message: "",
               binary: <<>>,
               reason: nil

  @doc false
  def new(reason, binary) do
    %__MODULE__{
      message: "Could not decode data (#{inspect(reason)})",
      binary: binary,
      reason: reason
    }
  end
end

defmodule Protox.IllegalTagError do
  @moduledoc """
  This error is thrown when decoding data with a field which tag is 0.
  """

  defexception message: "Field with illegal tag 0"

  @doc false
  def new() do
    %__MODULE__{}
  end
end

defmodule Protox.InvalidFieldAttribute do
  @moduledoc """
  This error is thrown when a field is constructed with an invalid atribute.
  """

  defexception message: ""

  @doc false
  def new(attribute, expected, got) do
    %__MODULE__{
      message:
        "Field attribute #{attribute} should be in #{inspect(expected)}, got #{inspect(got)}"
    }
  end
end

defmodule Protox.JsonDecodingError do
  @moduledoc """
  This error is thrown when a JSON payload could not be decoded to a protobuf message.
  """

  defexception message: "",
               reason: ""

  @doc false
  def new(reason) do
    %__MODULE__{
      message: "Could not decode JSON payload because #{reason}",
      reason: reason
    }
  end
end

defmodule Protox.JsonEncodingError do
  @moduledoc """
  This error is thrown when a protobuf message could not be encoded to JSON.
  """

  defexception message: "",
               protobuf_msg: nil,
               reason: ""

  @doc false
  def new(protobuf_msg, reason) do
    %__MODULE__{
      message: "Could not encode #{inspect(protobuf_msg.__struct__)} to JSON because #{reason}",
      protobuf_msg: protobuf_msg,
      reason: reason
    }
  end
end

defmodule Protox.RequiredFieldsError do
  @moduledoc """
  This error is thrown when encoding or decoding a Protobuf 2 message
  with unset required fields (that is, that have the value `nil`).
  """

  defexception message: "",
               missing_fields: []

  @doc false
  def new(missing_fields) do
    %__MODULE__{
      message: "Some required fields are not set: #{inspect(missing_fields)}",
      missing_fields: missing_fields
    }
  end
end
