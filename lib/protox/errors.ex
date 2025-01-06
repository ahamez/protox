defmodule Protox.DecodingError do
  @moduledoc """
  This error is thrown when a data could not be decoded.
  """

  defexception message: "",
               binary: <<>>

  @doc false
  def new(binary, reason) when is_binary(binary) and is_binary(reason) do
    %__MODULE__{
      message: "Could not decode data (#{reason})",
      binary: binary
    }
  end
end

defmodule Protox.EncodingError do
  @moduledoc """
  This error is thrown when a message could not be encoded.
  """

  defexception message: "",
               field: nil

  @doc false
  def new(field, reason) when is_atom(field) and is_binary(reason) do
    %__MODULE__{
      message: "Could not encode field #{inspect(field)} (#{reason})",
      field: field
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
