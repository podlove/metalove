defmodule Metalove.PodcastFeed do
  alias Metalove.Fetcher
  alias Metalove.PodcastFeedParser
  alias Metalove.Episode

  defstruct feed_url: nil,
            title: nil,
            link: nil,
            language: nil,
            subtitle: nil,
            author: nil,
            contributors: [],
            summary: nil,
            description: nil,
            image_url: nil,
            categories: nil,
            copyright: nil,
            episodes: nil

  def get_by_feed_url(url) do
    case Metalove.Repository.get({:feed, url}) do
      {:found, result} -> result
      _ -> nil
    end
  end

  def fetch_and_parse(feed_url) do
    {:ok, body, _headers, {_followed_url, _}} = Fetcher.fetch_and_follow(feed_url)

    {:ok, cast, episodes} = PodcastFeedParser.parse(body)

    if cast[:next_page_ur] != nil do
      spawn(__MODULE__, :collect_episodes, [cast, episodes, feed_url])
    end

    {feed, episodes} = feed_and_episodes_with_parsed_maps(cast, episodes, feed_url)

    {:ok, feed, episodes}
  end

  defp feed_and_episodes_with_parsed_maps(cast, episodes, feed_url) do
    {%__MODULE__{
       feed_url: feed_url,
       title: cast[:title],
       link: cast[:link],
       language: cast[:language],
       categories: cast[:categories],
       copyright: cast[:copyright],
       author: cast[:itunes_author],
       description: cast[:description],
       summary: cast[:itunes_summary],
       subtitle: cast[:itunes_subtitle],
       image_url: cast[:image],
       contributors: cast[:contributors],
       episodes: Enum.map(episodes, fn episode -> {:episode, feed_url, episode[:guid]} end)
     }, Enum.map(episodes, fn episode -> Episode.new(episode, feed_url) end)}
  end

  def collect_episodes(cast, episodes, feed_url) do
    case cast[:next_page_url] do
      url when is_binary(url) and byte_size(url) > 0 ->
        {:ok, body, _headers, {_followed_url, _}} = Fetcher.fetch_and_follow(url)
        {:ok, cast, page_episodes} = PodcastFeedParser.parse(body)
        collect_episodes(cast, episodes ++ page_episodes, feed_url)

      _ ->
        {feed, episodes} = feed_and_episodes_with_parsed_maps(cast, episodes, feed_url)

        episodes
        |> Enum.each(&Metalove.Repository.put_episode/1)

        Metalove.Repository.put_feed(feed)

        episodes
    end
  end
end

defimpl Jason.Encoder, for: Metalove.PodcastFeed do
  def encode(value, opts) do
    map =
      value
      |> Map.from_struct()
      |> Enum.map(fn
        {key, list} when is_list(list) ->
          {key,
           Enum.map(list, fn
             {:episode, feed_url, guid} -> %{feed: feed_url, guid: guid}
             e -> e
           end)}

        e ->
          e
      end)
      |> Map.new()

    Jason.Encode.map(map, opts)
  end
end
