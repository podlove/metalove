defmodule Metalove.Podcast do
  alias Metalove.PodcastFeed

  @derive Jason.Encoder
  # the content of the link tag in the main feed, minus the scheme and ://
  defstruct id: nil,
            # main feed url, when multiple feeds are present in the order of mp3, m4a, other
            main_feed_url: nil,
            feed_urls: [],
            created_at: DateTime.utc_now(),
            updated_at: DateTime.utc_now()

  def new_with_main_feed_url(main_feed_url) do
    {:ok, main_feed, main_feed_episodes, alternate_feed_urls} =
      PodcastFeed.fetch_and_parse(main_feed_url)

    main_feed_episodes
    |> Enum.each(&Metalove.Episode.store/1)

    Metalove.PodcastFeed.store(main_feed)

    add_feed_urls(
      %__MODULE__{
        id: id_from_link(main_feed.link),
        main_feed_url: main_feed_url,
        feed_urls: [main_feed_url]
      },
      alternate_feed_urls
    )
    |> Metalove.Repository.put_podcast()
  end

  def get_by_feed_url(feed_url) do
    case Metalove.PodcastFeed.get_by_feed_url(feed_url) do
      nil -> new_with_main_feed_url(feed_url)
      feed -> get_by_id(id_from_link(feed.link))
    end
  end

  def get_by_id(id) do
    case Metalove.Repository.get({:podcast, id}) do
      {:found, result} -> result
      _ -> nil
    end
  end

  def get_by_link(link) do
    get_by_id(id_from_link(link))
  end

  require Logger

  def add_feed_urls(%__MODULE__{} = podcast, []), do: podcast

  def add_feed_urls(%__MODULE__{} = podcast, [feed_url | url_list]) do
    add_feed_urls(
      if feed_url in podcast.feed_urls do
        podcast
      else
        spawn(PodcastFeed, :fetch_and_parse, [feed_url])

        %__MODULE__{
          podcast
          | feed_urls: [feed_url | podcast.feed_urls],
            updated_at: DateTime.utc_now()
        }
      end,
      url_list
    )
  end

  def id_from_link("https://" <> url), do: id_from_link(url)
  def id_from_link("http://" <> url), do: id_from_link(url)
  def id_from_link(url), do: String.trim_trailing(url, "/")
end
