defmodule Protox.Scalar do
  @moduledoc false

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

defmodule Protox.OneOf do
  @moduledoc false

  @type t() :: %__MODULE__{
          parent: atom()
        }

  @enforce_keys [:parent]
  defstruct [:parent]
end

defmodule Protox.Kind do
  @moduledoc false

  @typedoc """
  This type indicates how a field is encoded.
  """
  @type t() :: Protox.Scalar.t() | :packed | :unpacked | :map | Protox.OneOf.t()
end
