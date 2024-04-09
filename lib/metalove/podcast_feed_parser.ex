defmodule Metalove.PodcastFeedParser do
  import SweetXml, except: [parse: 1, parse: 2]
  @moduledoc false

  def parse(xml) do
    # IO.inspect(xml, label: "xml to parse")

    # workaround for issue with entities in attributes in xmerl
    # https://bugs.erlang.org/browse/ERL-837
    xml = replace_hex_entities(xml)

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
    |> Map.put(:explicit, explicit(channel))
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

  def explicit(nil), do: false

  def explicit(xml) do
    value = xpath(xml, ~x"itunes:explicit/text()"s)

    String.downcase(value) in ["yes", "true"]
  end

  # atom contributors
  #   <atom:contributor>
  #   <atom:name>Tim Pritlove</atom:name>
  #   <atom:uri>http://tim.pritlove.org/</atom:uri>
  # </atom:contributor>
  # <atom:contributor>
  #   <atom:name>Clemens Schrimpe</atom:name>
  # </atom:contributor>
  # <atom:contributor>
  #   <atom:name>hukl</atom:name>
  # </atom:contributor>
  # <atom:contributor>
  #   <atom:name>Denis Ahrens</atom:name>
  # </atom:contributor>
  # <atom:contributor>
  #   <atom:name>roddi</atom:name>
  # </atom:contributor>
  # <atom:contributor>
  #   <atom:name>Letty</atom:name>
  # </atom:contributor>

  # optionally parse the media: metadata, e.g. with http://feeds.twit.tv/mbw.xml
  #   <enclosure url="http://www.podtrac.com/pts/redirect.mp3/cdn.twit.tv/audio/mbw/mbw0643/mbw0643.mp3" length="52742271" type="audio/mpeg"/>
  # <media:content url="http://www.podtrac.com/pts/redirect.mp3/cdn.twit.tv/audio/mbw/mbw0643/mbw0643.mp3" fileSize="52742271" type="audio/mpeg" medium="audio">
  # 	<media:title type="plain">MBW 643: An Apple Branded Faraday Cage</media:title>
  # 	<media:description type="plain">Apple Hits Peak Smartphone</media:description>
  # 	<media:keywords>Apple, TWiT, MacBreak Weekly, leo laporte, Rene Ritchie, Andy Ihnatko, Alex Lindsay, MBW, tim cook, earnings, China, Steve Balmer, Steve Jobs, iot, Homekit, CES, privacy, iPhone, services, qualcomm, itunes, samsung, netflix, fortnite, brydge, iPad</media:keywords>
  # 	<media:thumbnail url="https://elroycdn.twit.tv/sites/default/files/styles/twit_slideshow_400x300/public/images/episodes/718441/hero/mbw0643_h264.00_40_52_38.still001.jpg?itok=L7Ap2PIo" width="400" height="225"/><media:rating scheme="urn:simple">nonadult</media:rating>
  # 	<media:rating scheme="urn:v-chip">tv-g</media:rating>
  # 	<media:category scheme="urn:iab:categories" label="Technology & Computing">IAB19</media:category>
  # 	<media:credit role="anchor person">Leo Laporte</media:credit>
  # 	<media:credit role="anchor person">Andy Ihnatko</media:credit>
  # 	<media:credit role="anchor person">Alex Lindsay</media:credit>
  # 	<media:credit role="reporter">Mikah Sargent</media:credit>
  # </media:content>

  def contributors(nil), do: []

  def contributors(xml) do
    xml
    |> xpath(~x"atom:contributor"l)
    |> Enum.map(fn e ->
      xmap(e, name: ~x"atom:name/text()"s, uri: ~x"atom:uri/text()"os)
      |> remove_empty()
    end)
    |> case do
      [] ->
        xml
        |> xpath(~x"media:content/media:credit"l)
        |> Enum.map(fn e ->
          xmap(e, name: ~x"./text()"s, role: ~x"@role"os)
          |> remove_empty()
        end)

      result ->
        result
    end
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

  # utility helper
  def replace_hex_entities(xml_string) do
    Regex.replace(~r/&#x([0-9a-fA-F]+);/, xml_string, fn _, hex ->
      [elem(Integer.parse(hex, 16), 0)] |> to_string
    end)
  end
end
