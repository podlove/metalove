defmodule Metalove.Episode do
  alias Metalove.Enclosure

  # <title>Shake Shake Shake Your Spices</title>
  # <itunes:author>John Doe</itunes:author>
  # <itunes:subtitle>A short primer on table spices</itunes:subtitle>
  # <itunes:summary><![CDATA[This week we talk about
  #     <a href="https://itunes/apple.com/us/book/antique-trader-salt-pepper/id429691295?mt=11">salt and pepper shakers</a>
  #     , comparing and contrasting pour rates, construction materials, and overall aesthetics. Come and join the party!]]></itunes:summary>
  # <itunes:image href="http://example.com/podcasts/everything/AllAboutEverything/Episode1.jpg"/>
  # <enclosure length="8727310" type="audio/x-m4a" url="http://example.com/podcasts/everything/AllAboutEverythingEpisode3.m4a"/>
  # <guid>http://example.com/podcasts/archive/aae20140615.m4a</guid>
  # <pubDate>Tue, 08 Mar 2016 12:00:00 GMT</pubDate>
  # <itunes:duration>07:04</itunes:duration>
  # <itunes:explicit>no</itunes:explicit>

  defstruct feed_url: nil,
            guid: nil,
            author: nil,
            title: nil,
            subtitle: nil,
            summary: nil,
            description: nil,
            image_url: nil,
            duration: nil,
            enclosure: nil,
            pub_date: nil

  def get_by_episode_id(episode_id) do
    case Metalove.Repository.get(episode_id) do
      {:found, result} -> result
      _ -> nil
    end
  end

  def new(map, feed_url) when is_map(map) do
    %__MODULE__{
      feed_url: feed_url,
      title: map[:title],
      guid: map[:guid],
      description: map[:description],
      duration: map[:duration],
      summary: map[:itunes_summary],
      subtitle: map[:itunes_subtitle],
      enclosure: %Enclosure{
        url: map[:enclosure_url],
        type: map[:enclosure_map],
        size: map[:enclosure_length]
      },
      pub_date: map[:publication_date],
      image_url: map[:image]
    }
  end
end
