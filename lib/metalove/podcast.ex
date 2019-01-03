defmodule Metalove.Podcast do
  alias Metalove.PodcastFeed

  @derive Jason.Encoder
  # the content of the link tag in the main feed, minus the scheme and ://
  defstruct id: nil,
            # main feed url, when multiple feeds are present in the order of mp3, m4a, other
            main_feed_url: nil,
            feed_urls: []

  def new_with_main_feed_url(main_feed_url) do
    {:ok, main_feed, main_feed_episodes} = PodcastFeed.fetch_and_parse(main_feed_url)

    main_feed_episodes
    |> Enum.each(&Metalove.Repository.put_episode/1)

    Metalove.Repository.put_feed(main_feed)

    result = %__MODULE__{
      id: id_from_link(main_feed.link),
      main_feed_url: main_feed_url,
      feed_urls: [main_feed_url]
    }

    Metalove.Repository.put_podcast(result)

    result
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

  defp id_from_link("https://" <> url), do: id_from_link(url)
  defp id_from_link("http://" <> url), do: id_from_link(url)
  defp id_from_link(url), do: String.trim_trailing(url, "/")
end
