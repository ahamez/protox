defmodule Protox.DefineEnum do
  @moduledoc false

  def define(enums) do
    for {enum_name, constants} <- enums do
      default_fun = make_enum_default(constants)
      encode_constants_funs = make_encode_enum_constants(constants)
      decode_constants_funs = make_decode_enum_constants(constants)

      module_ast =
        quote do
          unquote(default_fun)

          @spec encode(atom) :: integer | atom
          unquote(encode_constants_funs)
          def encode(x), do: x

          @spec decode(integer) :: atom | integer
          unquote(decode_constants_funs)
          def decode(x), do: x

          @spec constants() :: [{integer, atom}]
          def constants(), do: unquote(constants)
        end

      quote do
        defmodule unquote(enum_name) do
          @moduledoc false
          unquote(module_ast)
        end
      end
    end
  end

  defp make_enum_default(constant_values) do
    # proto2: the first entry is always the default value
    # proto3: the entry with value 0 is the default value, and protoc mandates the first entry
    # to have the value 0
    [{_, default_value} | _] = constant_values

    quote do
      @spec default() :: unquote(default_value)
      def default(), do: unquote(default_value)
    end
  end

  defp make_encode_enum_constants(constant_values) do
    for {value, constant} <- constant_values do
      quote do
        def encode(unquote(constant)), do: unquote(value)
      end
    end
  end

  defp make_decode_enum_constants(constant_values) do
    # Map.new -> unify enum aliases
    for {value, constant} <- Map.new(constant_values) do
      quote do
        def decode(unquote(value)), do: unquote(constant)
      end
    end
  end
end
