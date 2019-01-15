defmodule Metalove.Enclosure do
  # <enclosure length="8727310" type="audio/x-m4a" url="http://example.com/podcasts/everything/AllAboutEverythingEpisode3.m4a"/>

  alias Metalove.Fetcher

  @derive Jason.Encoder
  defstruct url: nil,
            type: nil,
            size: nil,
            created_at: DateTime.utc_now(),
            fetched_metadata_at: nil,
            metadata: nil

  def infer_mime_type(url) do
    URI.parse(url).path
    |> Path.extname()
    |> case do
      ".mp3" -> "audio/mpeg"
      ".mp4" -> "audio/mp4"
      ".m4a" -> "audio/mp4"
      _ -> "audio"
    end
  end

  def fetch_metadata(enclosure) do
    cond do
      enclosure.fetched_metadata_at == nil ->
        %__MODULE__{
          enclosure
          | fetched_metadata_at: DateTime.utc_now(),
            metadata: fetch_and_parse_metadata_p(enclosure.url, enclosure.type)
        }

      true ->
        enclosure
    end
  end

  def fetch_and_parse_metadata_p(url, type) do
    with "audio/mpeg" = type,
         {:ok, body, _headers} <- Fetcher.get_range(url, 0..(1024 * 128)) do
      {Metalove.MediaParser.ID3.parse_header(body), body}
    end
    |> case do
      {{:content_to_short, required_length}, _body} ->
        with {:ok, body, _headers} <- Fetcher.get_range(url, 0..required_length) do
          Metalove.MediaParser.ID3.parse(body)
        end

      {{:ok, _tag_size, _version, _revision, _flags, _rest}, body} ->
        Metalove.MediaParser.ID3.parse(body)
    end
    |> case do
      %{tags: tags} ->
        transform_id3_tags(tags)

      _ ->
        []
    end
  end

  def transform_id3_tags(tags) do
    transform_id3_tags(tags, %{})
  end

  defp transform_id3_tags([], %{chapters: chapters} = acc) do
    %{
      acc
      | chapters:
          chapters
          |> Enum.map(&transform_chapter_tag/1)
          |> Enum.reverse()
    }

    #    |> IO.inspect()
  end

  # |> IO.inspect(label: "Parsed tags:")
  defp transform_id3_tags([], acc), do: acc

  defp transform_id3_tags([h | tail], acc) do
    acc =
      case h do
        {:APIC, %{image_data: data, mime_type: type}} ->
          Map.put(acc, :cover_art, %{data: data, type: type})

        {:CHAP, _} = tuple ->
          Map.update(acc, :chapters, [tuple], fn list -> [tuple | list] end)

        _ ->
          acc
      end

    transform_id3_tags(tail, acc)
  end

  defp transform_chapter_tag({:CHAP, map}) do
    map[:sub_frames]
    |> Enum.reduce(
      %{
        start: format_milliseconds(map[:start_time])
      },
      fn
        {:TIT2, title}, acc ->
          Map.put(acc, :title, title)

        {:WXXX, %{link: link}}, acc ->
          Map.put(acc, :href, link)

        {:APIC, %{image_data: data, mime_type: type}}, acc ->
          Map.put(acc, :image, %{data: data, type: type})

        _el, acc ->
          acc
      end
    )
  end

  defp format_milliseconds(millis) do
    millis
    |> DateTime.from_unix!(:millisecond)
    |> DateTime.to_time()
    |> to_string
  end
end
