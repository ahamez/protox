defmodule Protox.RequiredFieldsError do
  @moduledoc """
  This error is thrown when encoding or decoding a Protobuf 2 message
  with unset required fields (that is, that have the value `nil`).
  """

  defexception message: "Some required fields are not set",
               missing_fields: []

  def new(missing_fields) do
    %__MODULE__{
      message: "Some required fields are not set: #{inspect missing_fields}",
      missing_fields: missing_fields
    }
  end
end
