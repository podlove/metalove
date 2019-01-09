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
    channel
    |> xmap(
      title: ~x"title/text()"s,
      link: ~x"link/text()"s,
      language: ~x"language/text()"s,
      copyright: ~x"copyright/text()"s,
      description: ~x"description/text()"s,
      itunes_summary: ~x"itunes:summary/text()"s,
      itunes_subtitle: ~x"itunes:subtitle/text()"s,
      itunes_keywords: ~x"itunes:keywords/text()"s,
      itunes_author: ~x"itunes:author/text()"s,
      image: ~x"itunes:image/@href"s,
      next_page_url: ~x"atom:link[@rel='next']/@href"s,
      alternate_urls: ~x"atom:link[@rel='alternate']/@href"sl
    )
    |> Map.put(:categories, categories(channel))
    |> Map.put(:contributors, contributors(channel))
    |> Map.put(:itunes_owner, owner(channel))
    |> remove_empty()
  end

  def episode_fields(item) do
    item
    |> xmap(
      title: ~x"title/text()"s,
      link: ~x"link/text()"s,
      guid: ~x"guid/text()"s,
      description: ~x"description/text()"s,
      duration: ~x"itunes:duration/text()"s,
      itunes_summary: ~x"itunes:summary/text()"s,
      itunes_subtitle: ~x"itunes:subtitle/text()"s,
      itunes_author: ~x"itunes:author/text()"s,
      enclosure_url: ~x"enclosure/@url"s,
      enclosure_type: ~x"enclosure/@type"s,
      enclosure_length: ~x"enclosure/@length"i,
      itunes_season: ~x"itunes:season/text()"s,
      itunes_episode: ~x"itunes:episode/text()"s,
      image: ~x"itunes:image/@href"s,
      content_encoded: ~x"content:encoded/text()"s
    )
    |> Map.put(:contributors, contributors(item))
    |> Map.put(:publication_date, date_time(xpath(item, ~x"pubDate/text()"s)))
    |> Map.put(:chapters, chapters(item))
    |> remove_empty()
  end

  defp remove_empty(map) do
    map
    |> Enum.filter(fn {_key, value} -> value != "" end)
    |> Map.new()
  end

  def owner(nil), do: nil

  def owner(xml) do
    xml
    |> xmap(
      name: ~x"itunes:owner/itunes:name/text()"s,
      email: ~x"itunes:owner/itunes:email/text()"os
    )
    |> remove_empty()
  end

  def contributors(nil), do: []

  def contributors(xml) do
    xml
    |> xpath(~x"atom:contributor"l)
    |> Enum.map(fn e ->
      xmap(e, name: ~x"atom:name/text()"s, uri: ~x"atom:uri/text()"os)
      |> remove_empty()
    end)
  end

  def categories(nil), do: []

  def categories(xml) do
    xml
    |> xpath(~x"itunes:category"el)
    |> Enum.map(&xpath(&1, ~x"//itunes:category/@text"sl))
  end

  def chapters(nil), do: []

  def chapters(xml) do
    xml
    |> xpath(~x"psc:chapters/psc:chapter"el)
    |> Enum.map(fn e ->
      xmap(e,
        start: ~x"@start"s,
        title: ~x"@title"os,
        href: ~x"@href"os,
        image: ~x"@image"os
      )
      |> remove_empty()
    end)
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
