defmodule Metalove.Episode do
  @moduledoc """
  Defines a `Metalove.Episode` struct reprsenting Episodes. Belongs to a `Metalove.PodcastFeed`. Provides functions to access the data.
  """

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

  @derive Jason.Encoder
  defstruct feed_url: nil,
            guid: nil,
            author: nil,
            title: nil,
            subtitle: nil,
            summary: nil,
            description: nil,
            content_encoded: nil,
            image_url: nil,
            duration: nil,
            enclosure: nil,
            link: nil,
            contributors: [],
            chapters: [],
            pub_date: nil,
            season: nil,
            episode: nil

  @typedoc """
  All information for an Episode.

  Field information:
  * `chapters` A list of maps for the chapters, fields are `start`, `title`, `href`, `image` - image can either be an url or a `data`,`type` map if parsed from metadata
  * `contributors` A list of maps containing the contributors, fields are `name`, `uri`

  ```
  %Metalove.Episode{
    author: "ATP",
    chapters: [],
    content_encoded: nil,
    contributors: [],
    description: "<ul>\n<li>Follow-up:<ul>\n<li>Hosting a podcast for free on <a href=\"https://anchor.fm/\">Anchor</a> or <a href=\"https://soundcloud.com/\">SoundCloud</a></li>\n<li>Contacts syncing <a href=\"https://support.apple.com/en-us/HT202158\">limits</a></li>\n</ul>\n</li>\n<li>Mojave stability<ul>\n<li><a href=\"https://mjtsai.com/blog/2019/02/19/t2-macs-have-a-serious-audio-glitching-bug/\">Possible T2 Mac audio glitching bug</a></li>\n</ul>\n</li>\n<li>Rumor explosion from Ming-Chi Kuo and Mark Gurman<ul>\n<li><a href=\"https://www.macrumors.com/2019/02/17/16-inch-macbook-pro-2019-kuo/\">16-inch MacBook Pro</a><ul>\n<li><a href=\"http://drops.caseyliss.com/M3VSNM\">iBook G4</a></li>\n</ul>\n</li>\n<li><a href=\"https://www.macrumors.com/2019/02/17/apple-31-inch-6k-display-mini-led-kuo/\">31.6\" 6K3K display with Mini-LED-like backlight</a></li>\n<li><a href=\"https://www.macrumors.com/2019/02/20/apple-mulling-preview-mac-pro-wwdc/\">Apple Mulling Preview of New Modular Mac Pro at WWDC in June</a></li>\n<li><a href=\"https://www.bloomberg.com/news/articles/2019-02-20/apple-is-said-to-target-combining-iphone-ipad-mac-apps-by-2021\">Marzipan rumors</a><ul>\n<li><a href=\"https://en.wikipedia.org/wiki/Overton_window\">Overton window</a></li>\n</ul>\n</li>\n</ul>\n</li>\n<li><code>#askatp</code>:<ul>\n<li>Could the next Apple TV be wireless? (via <a href=\"https://twitter.com/ecormany/status/1085287581166768128\">Ed Cormany</a>)</li>\n<li>Is wireless CarPlay a deal-breaker? (via <a href=\"https://twitter.com/eddielee6/status/1095434200155672577\">Eddie Lee</a>)</li>\n<li>How is season 3 of <a href=\"https://www.amazon.com/thegrandtour\">The Grand Tour</a>? (via <a href=\"https://twitter.com/syllabub69/status/1097808914907770880\">Paul Walker</a> (not that one))</li>\n</ul>\n</li>\n<li>Post-show: Apple ID Management<ul>\n<li><a href=\"https://developer.apple.com/support/account/authentication/\">Two factor requirements</a></li>\n</ul>\n</li>\n</ul>\n<p>Sponsored by:</p>\n<ul>\n<li><a href=\"https://www.boxysuite.com/\">BoxySuite</a>: A beautiful suite of Mac apps for Gmail and Google Calendar. Get a 30% lifetime discount on all plans with code <strong>atp30</strong>.</li>\n<li><a href=\"http://fractureme.com/atp\">Fracture</a>: Photos printed in vivid color directly on glass. Get a special discount off your first order.</li>\n</ul>",
    duration: "02:05:44",
    enclosure: %Metalove.Enclosure{
      created_at: #DateTime<2019-02-23 15:27:19.946286Z>,
      fetched_metadata_at: #DateTime<2019-02-24 13:55:23.001144Z>,
      metadata: %{
        chapters: [
          %{start: "00:00:00.000", title: "Free podcast hosting"},
          %{start: "00:04:06.457", title: "Gmail misspellings"},
          %{
            href: "https://support.apple.com/en-us/HT202158",
            start: "00:07:01.432",
            title: "Contacts syncing"
          },
          %{
            href: "https://www.fractureme.com/atp",
            start: "00:16:24.975",
            title: "Sponsor: Fracture"
          },
          %{start: "00:18:31.475", title: "Mojave stability"},
          %{
            href: "https://mjtsai.com/blog/2019/02/19/t2-macs-have-a-serious-audio-glitching-bug/",
            start: "00:22:58.350",
            title: "USB audio bug?"
          },
          %{
            href: "https://www.boxysuite.com/",
            start: "00:36:14.975",
            title: "Sponsor: Boxy Suite (code ATP30)"
          },
          %{
            href: "https://www.macrumors.com/2019/02/17/16-inch-macbook-pro-2019-kuo/",
            start: "00:37:33.600",
            title: "16\" MBP rumor"
          },
          %{
            href: "https://www.macrumors.com/2019/02/17/apple-31-inch-6k-display-mini-led-kuo/",
            start: "00:50:34.975",
            title: "31.6\" 6K3K display rumor"
          },
          %{
            href: "https://www.macrumors.com/2019/02/20/apple-mulling-preview-mac-pro-wwdc/",
            start: "01:07:52.475",
            title: "Mac Pro rumor"
          },
          %{
            href: "https://www.bloomberg.com/news/articles/2019-02-20/apple-is-said-to-target-combining-iphone-ipad-mac-apps-by-2021",
            start: "01:14:43.475",
            title: "Marzipan rumor"
          },
          %{start: "01:36:13.975", title: "#askatp: Cheap Apple TV"},
          %{start: "01:42:49.475", title: "#askatp: Wireless CarPlay"},
          %{start: "01:46:43.975", title: "#askatp: The Grand Tour"},
          %{
            href: "http://jonathanmann.net/",
            start: "01:51:12.975",
            title: "Ending theme"
          },
          %{start: "01:52:15.475", title: "John's Apple ID"}
        ],
        cover_art: %{
          data: <<255, 216, 255, 225, 0, 24, 69, 120, 105, 102, 0, 0, 73, 73, 42,
            0, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 255, 236, 0, 17, 68, 117, 99,
            107, 121, ...>>,
          type: "image/jpeg"
        }
      },
      size: 60482143,
      type: "audio/mpeg",
      url: "http://traffic.libsyn.com/atpfm/atp314.mp3"
    },
    episode: nil,
    feed_url: "http://atp.fm/episodes?format=RSS",
    guid: "513abd71e4b0fe58c655c105:513abd71e4b0fe58c655c111:5c6e2706c830252a16aaa9ff",
    image_url: "http://static1.squarespace.com/static/513abd71e4b0fe58c655c105/t/52c45a37e4b0a77a5034aa84/1388599866232/1500w/Artwork.jpg",
    link: "http://atp.fm/episodes/314",
    pub_date: #DateTime<2019-02-21 19:25:00+00:00 GMT Etc/GMT+0>,
    season: nil,
    subtitle: "Hopeful rumors for 2019 Macs, the state of Mojave, and a tale of Apple ID woe.",
    summary: nil,
    title: "314: Kernel Panic in the Night"
  }
  ```
  """
  @type t :: %__MODULE__{
          feed_url: String.t(),
          guid: String.t(),
          author: nil | String.t(),
          title: nil | String.t(),
          subtitle: nil | String.t(),
          summary: nil | String.t(),
          description: nil | String.t(),
          content_encoded: nil | String.t(),
          image_url: nil | String.t(),
          duration: nil | String.t(),
          enclosure: nil | Metalove.Enclosure.t(),
          link: nil | String.t(),
          contributors: list(map()),
          chapters: list(map()),
          pub_date: nil | DateTime.t(),
          season: nil | String.t(),
          episode: nil | String.t()
        }

  @doc """
  Return eipsode of this ID if existing (episode IDs are of style `{:episode, feed_url, episode_guid}`)
  """
  @spec get_by_episode_id({:episode, String.t(), String.t()}) :: __MODULE__.t() | nil
  def get_by_episode_id(episode_id) do
    case Metalove.Repository.get(episode_id) do
      {:found, result} -> result
      _ -> nil
    end
  end

  @doc false
  def store(%__MODULE__{} = episode) do
    Metalove.Repository.put_episode(episode)
  end

  @doc false
  def new(map, feed_url) when is_map(map) do
    %__MODULE__{
      feed_url: feed_url,
      author: map[:itunes_author],
      title: map[:title],
      guid: map[:guid],
      link: map[:link],
      description: map[:description],
      content_encoded: map[:content_encoded],
      duration: map[:duration],
      summary: map[:itunes_summary],
      subtitle: map[:itunes_subtitle],
      enclosure: %Enclosure{
        url: map[:enclosure_url],
        type: map[:enclosure_type] || Enclosure.infer_mime_type(map[:enclosure_url]),
        size: map[:enclosure_length]
      },
      pub_date: map[:publication_date],
      image_url: map[:image],
      contributors: map[:contributors],
      chapters: map[:chapters],
      season: map[:itunes_season],
      episode: map[:itunes_episode]
    }
  end

  @doc """
  Returns a list of all known enclosures for that Episode (e.g. if podcast has multiple feeds, all enclosures of the episodes with the same guid)
  """
  def all_enclosures(%__MODULE__{feed_url: feed_url, guid: guid, enclosure: enclosure}) do
    Metalove.Podcast.get_by_feed_url(feed_url).feed_urls
    |> Enum.reduce([enclosure], fn
      ^feed_url, acc ->
        acc

      url, acc ->
        case __MODULE__.get_by_episode_id({:episode, url, guid}) do
          %__MODULE__{} = other_format -> [other_format.enclosure | acc]
          _ -> acc
        end
    end)
    |> Enum.reverse()
  end

  @doc """
  Returns either `{:image, %{data: binary(), type: String.t()}}` if a parsed metadata episode image exists, otherwise `{:image_url, String.t()}` if a known image url exists, `:not_found` otherwise
  """
  def episode_image(%__MODULE__{} = episode) do
    case episode.enclosure.metadata[:cover_art] do
      image when is_map(image) ->
        {:image, image}

      _ ->
        case episode.image_url || Metalove.PodcastFeed.get_by_feed_url(episode.feed_url).image_url do
          nil -> :not_found
          url -> {:image_url, url}
        end
    end
  end
end
