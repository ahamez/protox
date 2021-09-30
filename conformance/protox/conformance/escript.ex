defmodule Protox.Conformance.Escript do
  @moduledoc false

  # An escript that will be called by the protobuf conformance test runner
  # It reads a conformance test request on its standard input and outputs
  # the test results on the standard output.

  use Protox,
    files: [
      "./conformance/protox/conformance/conformance.proto",
      "./test/samples/test_messages_proto2.proto",
      "./test/samples/test_messages_proto3.proto"
    ]

  def main(_args) do
    run()
  end

  defp run() do
    :io.setopts(:standard_io, encoding: :latin1)

    :ok = File.mkdir_p("conformance_report")

    "./conformance_report/report_#{System.system_time()}.txt"
    |> File.open!([:write])
    |> loop()
  end

  defp loop(log_file) do
    IO.binwrite(log_file, "\n---------\n")

    case IO.binread(:stdio, 4) do
      :eof ->
        IO.binwrite(log_file, "EOF\n")
        :ok

      {:error, reason} ->
        IO.binwrite(log_file, "Error: #{inspect(reason)}\n")
        {:error, reason}

      <<len::unsigned-little-32>> ->
        :stdio
        |> IO.binread(len)
        |> dump_data(log_file)
        |> Conformance.ConformanceRequest.decode()
        |> handle_request(log_file)
        |> make_message_bytes()
        |> output(log_file)

        loop(log_file)
    end
  end

  defp handle_request(
         {
           :ok,
           req = %Conformance.ConformanceRequest{
             requested_output_format: requested_output_format,
             payload: {payload_type, _}
           }
         },
         log_file
       )
       when requested_output_format in [:PROTOBUF, :JSON] and
              payload_type in [:protobuf_payload, :json_payload] do
    IO.binwrite(log_file, "Will parse protobuf\n")

    if Conformance.ConformanceRequest.unknown_fields(req) != [] do
      IO.binwrite(log_file, "Warning, request contains unknown fields\n")
    end

    IO.binwrite(log_file, "#{inspect(req)}\n")

    {_payload_type, payload} = req.payload

    IO.binwrite(
      log_file,
      "payload_type: #{payload_type}\npayload: #{inspect(payload, limit: :infinity)}\n"
    )

    proto_type =
      case req.message_type do
        "protobuf_test_messages.proto3.TestAllTypesProto3" ->
          ProtobufTestMessages.Proto3.TestAllTypesProto3

        "protobuf_test_messages.proto2.TestAllTypesProto2" ->
          ProtobufTestMessages.Proto2.TestAllTypesProto2

        "conformance.FailureSet" ->
          Conformance.FailureSet

        "" ->
          ProtobufTestMessages.Proto3.TestAllTypesProto3
      end

    decode_payload_fun =
      case payload_type do
        :protobuf_payload -> fn -> proto_type.decode(payload) end
        :json_payload -> fn -> proto_type.json_decode(payload) end
      end

    case decode_payload_fun.() do
      {:ok, msg} ->
        IO.binwrite(log_file, "Parse: success.\n")
        IO.binwrite(log_file, "Message: #{inspect(msg, limit: :infinity)}\n")

        try do
          encoded_payload =
            case requested_output_format do
              :JSON -> msg |> Protox.json_encode!() |> :binary.list_to_bin()
              :PROTOBUF -> msg |> Protox.encode!() |> :binary.list_to_bin()
            end

          IO.binwrite(
            log_file,
            "Encoded payload: #{inspect(encoded_payload, limit: :infinity)}\n"
          )

          case requested_output_format do
            :JSON ->
              %Conformance.ConformanceResponse{result: {:json_payload, encoded_payload}}

            :PROTOBUF ->
              %Conformance.ConformanceResponse{result: {:protobuf_payload, encoded_payload}}
          end
        rescue
          e ->
            %Conformance.ConformanceResponse{result: {:serialize_error, e.message}}
        end

      {:error, reason} ->
        IO.binwrite(log_file, "Parse error: #{inspect(reason)}\n")

        %Conformance.ConformanceResponse{
          result: {:parse_error, "Parse error: #{inspect(reason)}"}
        }
    end
  end

  # All JSON and TEXT related tests are skipped.
  defp handle_request({:ok, req}, log_file) do
    skip_reason =
      case {req.requested_output_format, req.payload} do
        {:UNSPECIFIED, _} ->
          "unspecified input"

        {_, nil} ->
          "unset payload"

        {_, {:text_payload, _}} ->
          "text input"

        {:TEXT_FORMAT, _} ->
          "text output"
      end

    IO.binwrite(log_file, "SKIPPED\n")
    IO.binwrite(log_file, "Reason: #{inspect(skip_reason)}\n")
    IO.binwrite(log_file, "#{inspect(req)}\n")
    %Conformance.ConformanceResponse{result: {:skipped, "SKIPPED"}}
  end

  defp handle_request({:error, reason}, log_file) do
    IO.binwrite(log_file, "ConformanceRequest parse error: #{inspect(reason)}\n")

    %Conformance.ConformanceResponse{
      result: {:parse_error, "Parse error: #{inspect(reason)}"}
    }
  end

  defp dump_data(data, log_file) do
    IO.binwrite(log_file, "Received #{inspect(data, limit: :infinity)}\n")
    data
  end

  defp output(data, log_file) do
    IO.binwrite(log_file, "Will write #{byte_size(data)} bytes\n")
    IO.binwrite(:stdio, data)
  end

  defp make_message_bytes(msg) do
    data = msg |> Protox.encode!() |> :binary.list_to_bin()
    <<byte_size(data)::unsigned-little-32, data::binary>>
  end
end
