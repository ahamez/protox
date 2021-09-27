defimpl Protox.JsonMessageDecoder, for: Google.Protobuf.FieldMask do
  def decode_message(initial_message, json) do
    paths =
      json
      |> String.split(",")
      |> Enum.map(&Macro.underscore/1)

    struct!(initial_message, paths: paths)
  end
end

defimpl Protox.JsonMessageEncoder, for: Google.Protobuf.FieldMask do
  def encode_message(msg, json_encode) do
    case check_paths(msg.paths) do
      :ok ->
        msg.paths
        |> Enum.map_join(",", &lower_camel_case/1)
        |> json_encode.()

      :error ->
        raise Protox.JsonEncodingError.new(msg, "path is invalid")
    end
  end

  defp lower_camel_case(string) do
    string
    |> String.split(".")
    |> Enum.map(fn str ->
      <<first, rest::binary>> = Macro.camelize(str)

      <<String.downcase(<<first>>, :ascii)::binary, rest::binary>>
    end)
    |> Enum.join(".")
  end

  defp check_paths(paths) do
    res =
      Enum.any?(paths, fn path ->
        with false <- has_too_many_underscores?(path),
             false <- has_a_number_in_path_component?(path),
             false <- has_camel_cased_components?(path) do
          false
        else
          _ ->
            true
        end
      end)

    if res do
      :error
    else
      :ok
    end
  end

  defp has_too_many_underscores?(path) do
    String.contains?(path, "__")
  end

  defp has_a_number_in_path_component?(path) do
    path
    |> String.split("_")
    |> Enum.any?(fn str ->
      String.starts_with?(str, ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"])
    end)
  end

  defp has_camel_cased_components?(path) do
    path
    |> String.split("_")
    |> Enum.any?(fn str -> str == lower_camel_case(str) and not (str == String.downcase(str)) end)
  end
end
