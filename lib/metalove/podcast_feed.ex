defmodule Metalove.PodcastFeed do
  @moduledoc """
  Defines a `Metalove.PodcastFeed` struct to represent a scraped and parsed feed. Belongs to an `Metalove.Podcast` and has `Metalove.Episodes`
  """

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
            episodes: nil,
            waiting_for_pages: false,
            created_at: DateTime.utc_now(),
            updated_at: DateTime.utc_now()

  @typedoc """
  Represents a podcast feed.

  Fields:
  * `:feed_url` URL of that feed
  * `:title` Title
  * `:language`
  * `:author`
  * `:contributors`
  * `:summary`
  * `:description`
  * `:image_url`
  * `:categories`
  * `:copyright`
  * `:episodes` list of episode id tuples, for a paged feed that eventually contains all
  """
  @type t :: %__MODULE__{
          feed_url: String.t(),
          title: String.t() | nil,
          language: String.t() | nil,
          author: String.t() | nil,
          contributors: list() | nil,
          summary: String.t() | nil,
          description: String.t() | nil,
          image_url: String.t() | nil,
          categories: list | nil,
          copyright: String.t() | nil,
          episodes: list,
          waiting_for_pages: boolean(),
          created_at: DateTime.t(),
          updated_at: DateTime.t()
        }
  @doc """
  Existing `Metalove.PodcastFeed` for that url, otherwise nil
  """
  @spec get_by_feed_url(String.t()) :: Metalove.PodcastFeed.t() | nil
  def get_by_feed_url(url) do
    case Metalove.Repository.get({:feed, url}) do
      {:found, result} -> result
      _ -> nil
    end
  end

  @doc """
  Existing `Metalove.PodcastFeed` for that url after all pages are fetched, otherwise nil
  """
  def get_by_feed_url_await_all_pages(url, timeout \\ 30_000) do
    # should not be a busy wait
    cond do
      timeout <= 0 ->
        nil

      true ->
        case get_by_feed_url(url) do
          nil ->
            nil

          feed ->
            feed.waiting_for_pages
            |> case do
              false ->
                feed

              true ->
                :timer.sleep(1000)
                get_by_feed_url_await_all_pages(url, timeout - 1_000)
            end
        end
    end
  end

  @doc """
  Existing `Metalove.PodcastFeed` for that url after all metadata is fetched, otherwise nil. Make sure to trigger the metadata media fetch first by calling `Metalove.PodcastFeed.trigger_episode_metadata_scrape(feed)` with all episodes present.
  """
  def get_by_feed_url_await_all_metdata(url, timeout \\ 30_000) do
    # should not be a busy wait
    cond do
      timeout <= 0 ->
        nil

      true ->
        case get_by_feed_url_await_all_pages(url) do
          nil ->
            nil

          feed ->
            case did_all_episodes_fetch_metadata?(feed) do
              true ->
                feed

              false ->
                :timer.sleep(1000)
                get_by_feed_url_await_all_metdata(url, timeout - 1_000)
            end
        end
    end
  end

  defp did_all_episodes_fetch_metadata?(%__MODULE__{} = feed) do
    feed.episodes
    |> Enum.map(&Metalove.Episode.get_by_episode_id/1)
    |> Enum.map(& &1.enclosure.fetched_metadata_at)
    |> Enum.all?(&(&1 != nil))
  end

  require Logger

  def fetch_and_parse(feed_url) do
    {:ok, body, _headers, {_followed_url, _}} = Fetcher.fetch_and_follow(feed_url)

    {:ok, cast, episodes} = PodcastFeedParser.parse(body)

    alternate_feed_urls = cast[:alternate_urls] || []

    cast =
      if cast[:next_page_url] != nil do
        spawn(__MODULE__, :collect_episodes, [cast, episodes, feed_url])
        Map.put(cast, :waiting_for_pages, true)
      else
        cast
      end

    {feed, episodes} = feed_and_episodes_with_parsed_maps(cast, episodes, feed_url)

    {:ok, feed, episodes, alternate_feed_urls}
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
       waiting_for_pages: cast[:waiting_for_pages] || false,
       episodes: Enum.map(episodes, fn episode -> {:episode, feed_url, episode[:guid]} end)
     }, Enum.map(episodes, fn episode -> Episode.new(episode, feed_url) end)}
  end

  require Logger

  @doc false
  def collect_episodes(cast, episodes, feed_url) do
    Logger.debug("collect_episodes: #{inspect(cast[:next_page_url])}")

    case cast[:next_page_url] do
      url when is_binary(url) and byte_size(url) > 0 ->
        {:ok, body, _headers, {_followed_url, _}} = Fetcher.fetch_and_follow(url)
        {:ok, cast, page_episodes} = PodcastFeedParser.parse(body)
        collect_episodes(cast, episodes ++ page_episodes, feed_url)

      _ ->
        {feed, episodes} = feed_and_episodes_with_parsed_maps(cast, episodes, feed_url)

        episodes
        |> Enum.each(&Metalove.Episode.store/1)

        store(feed)

        episodes
    end
  end

  @doc false
  def store(feed) do
    Metalove.Repository.put_feed(feed)
    feed
  end

  @doc false
  def trigger_episode_metadata_scrape(feed) do
    feed.episodes
    |> spread_list(6)
    |> Enum.each(fn sublist ->
      spawn(__MODULE__, :scrape_episode_metadata, [sublist])
      # Task.async(fn -> scrape_episode_metadata(sublist) end)
    end)
  end

  # conditionally export all for testing purposes
  @compile if Mix.env() == :test, do: :export_all

  defp spread_list(list, count) do
    list
    |> Enum.reduce({[], Stream.cycle([[]]) |> Enum.take(count)}, fn
      e, {left, [head | right]} ->
        {[[e | head] | left], right}

      e, {left, []} ->
        [head | right] = Enum.reverse(left)
        {[[e | head]], right}
    end)
    |> case do
      {left, right} ->
        Enum.reverse(right) ++ left
    end
    |> Enum.drop_while(&(&1 == []))
    |> Enum.map(&Enum.reverse/1)
    |> Enum.reverse()
  end

  @doc """
  Scrape metadata from the episode media files if possible.
  """
  def scrape_episode_metadata(episode_ids) do
    episode_ids
    |> Enum.each(fn id ->
      case Metalove.Episode.get_by_episode_id(id) do
        %Metalove.Episode{} = episode ->
          enclosure = Metalove.Enclosure.fetch_metadata(episode.enclosure)
          Metalove.Episode.store(%Metalove.Episode{episode | enclosure: enclosure})

        _ ->
          :nothing
      end
    end)
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
