defmodule Metalove.PodcastFeedParser do
  import SweetXml, except: [parse: 1, parse: 2]

  def parse(xml) do
    # IO.inspect(xml, label: "xml to parse")

    try do
      with channel <- xpath(xml, ~x"//channel"e),
           items <- xpath(channel, ~x"item"el),
           podcast_fields <- podcast_fields(channel),
           item_fields <- Enum.map(items, &episode_fields/1) do
        {:ok, podcast_fields, item_fields}
      end
    catch
      :exit, _e ->
        {:error, :no_valid_feed}
    end
  end

  def podcast_fields(channel) do
    %{
      title: xpath(channel, ~x"title/text()"s),
      link: xpath(channel, ~x"link/text()"s),
      language: xpath(channel, ~x"language/text()"s),
      copyright: xpath(channel, ~x"copyright/text()"s),
      description: xpath(channel, ~x"description/text()"s),
      itunes_summary: xpath(channel, ~x"itunes:summary/text()"s),
      itunes_subtitle: xpath(channel, ~x"itunes:subtitle/text()"s),
      itunes_author: xpath(channel, ~x"itunes:author/text()"s),
      itunes_owner_email: xpath(channel, ~x"itunes:owner/itunes:email/text()"s),
      itunes_owner_name: xpath(channel, ~x"itunes:owner/itunes:name/text()"s),
      image: xpath(channel, ~x"itunes:image/@href"s)
    }
  end

  def episode_fields(item) do
    %{
      title: xpath(item, ~x"title/text()"s),
      guid: xpath(item, ~x"guid/text()"s),
      description: xpath(item, ~x"description/text()"s),
      duration: xpath(item, ~x"itunes:duration/text()"s),
      itunes_summary: xpath(item, ~x"itunes:summary/text()"s),
      itunes_subtitle: xpath(item, ~x"itunes:subtitle/text()"s),
      enclosure_url: xpath(item, ~x"enclosure/@url"s),
      enclosure_type: xpath(item, ~x"enclosure/@type"s),
      enclosure_length: xpath(item, ~x"enclosure/@length"i),
      publication_date: date_time(xpath(item, ~x"pubDate/text()"s)),
      image: xpath(item, ~x"itunes:image/@href"s)
    }
  end

  # fixme: very naive. works with Publisher but must be tolerant of whatever formats
  def date_time(timestring) do
    trimmed =
      timestring
      |> String.trim()

    case Timex.parse(trimmed, "{RFC1123}") do
      {:ok, result} ->
        result

      _ ->
        case Timex.parse(trimmed <> " +0000", "{RFC1123}") do
          {:ok, result} -> result
          _ -> nil
        end
    end
  end
end
