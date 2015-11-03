defmodule Cafex.Protocol.OffsetFetch do
  @behaviour Cafex.Protocol.Decoder

  defmodule Request do
    defstruct consumer_group: nil,
              topics: []

    @type t :: %Request{consumer_group: binary,
                        topics: [{topic_name :: String.t,
                                  partitions :: [integer]}]}
  end

  defmodule Response do
    defstruct topics: []

    @type t :: %Response{topics: [{partition :: integer,
                                      offset :: integer,
                                    metadata :: String.t,
                                      error  :: Cafex.Protocol.Errors.t}]}
  end

  defimpl Cafex.Protocol.Request, for: Request do
    def api_key(_), do: 9
    def encode(request) do
      Cafex.Protocol.OffsetFetch.encode(request)
    end
  end

  def encode(%{consumer_group: consumer_group, topics: topics}) do
    [Cafex.Protocol.encode_string(consumer_group),
     Cafex.Protocol.encode_array(topics, &encode_topic/1)]
    |> IO.iodata_to_binary
  end

  defp encode_topic({topic, partitions}) do
    [Cafex.Protocol.encode_string(topic),
     Cafex.Protocol.encode_array(partitions, &encode_partition/1)]
  end
  defp encode_partition(partition), do: << partition :: 32-signed >>

  def decode(data) when is_binary(data) do
    {topics, _} = Cafex.Protocol.decode_array(data, &decode_topic/1)
    %Response{topics: topics}
  end

  defp decode_topic(<< size :: 16-signed, topic :: size(size)-binary, rest :: binary >>) do
    {partitions, rest} = Cafex.Protocol.decode_array(rest, &decode_partition/1)
    {{topic, partitions}, rest}
  end

  defp decode_partition(<< partition :: 32-signed, offset :: 64-signed,
                           size :: 16-signed, metadata :: size(size)-binary,
                           error_code :: 16-signed, rest :: binary >>) do
    {{partition, offset, metadata, Cafex.Protocol.Errors.error(error_code)}, rest}
  end
end
