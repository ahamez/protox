defmodule Protox.Scalar do
  @moduledoc """
  Represents a scalar field in a Protocol Buffer message.

  This module defines a struct that holds information about a scalar field,
  particularly its default value. Scalar fields are the basic data types
  such as integers, floats, booleans, strings.

  The default value is used when a field is not present in the encoded message.
  """

  @typedoc """
  All the possible types that can be used as a default value for a scalar.
  """
  @type scalar_default_value_type ::
          binary()
          | boolean()
          | integer()
          | float()
          | atom()
          | nil

  @type t() :: %__MODULE__{
          default_value: scalar_default_value_type()
        }

  @enforce_keys [:default_value]
  defstruct [:default_value]
end
