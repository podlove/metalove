defmodule Metalove do
  @moduledoc """
  The main application interface.
  """

  @doc ~S"""
  Convenience entry point.

  Args:
    * `url` - URL of a podcast feed or webpage (e.g. "atp.fm" or "https://freakshow.fm/feed/m4a/")

  Return values:
    * `Metalove.Podcast.t()` if a podcast could be deduced and fetched from the given url. Metalove will return once one page of a feed has been parsed, but will start parsing all pages of the feed as well as gathering all ID3 metadata if available.
    * `nil` if no podcast could be found or be associated with the given url

  """
  @spec get_podcast(binary()) ::
          Metalove.Podcast.t() | nil
  def get_podcast(url) do
    feed_url_fn = fn ->
      case get_feed_url(url, follow_first: true) do
        {:ok, feed_url} -> feed_url
        _ -> nil
      end
    end

    case Metalove.Repository.fetch({:url, url}, feed_url_fn) do
      nil -> nil
      feed_url -> Metalove.Podcast.get_by_feed_url(feed_url)
    end
  end

  @doc ~S"""
    Purges all cached and parsed data.
  """

  def purge do
    Metalove.Repository.purge()
    Metalove.FetcherCache.purge()
  end

  @doc ~S"""

  Takes a url of a any website (shortform without `http(s)://` in front is also allowed and tries to follow the redirections, links and html to find a rss feed of a podcast.

  Args:
    * `url` - URL of a podcast feed or webpage (e.g. "atp.fm" or "https://freakshow.fm/feed/m4a/")

  Return values:
    * `{:ok, feed_url}` if successful and the header type indicates rss/xml
    * `{:candidates, [{potential_url, title},…]}` if a html page with multiple links was encountered
    * `{:error, :not_found}` if we could not dedude any podcast

  ## Examples

      iex> {:candidates, list} = Metalove.get_feed_url("freakshow.fm")
      iex> hd(list)
      {"http://freakshow.fm/feed/mp3", "Podcast Feed: Freak Show (MP3 Audio)"}
  """

  @spec get_feed_url(binary, Keyword.t()) ::
          {:ok, binary()} | {:candidates, [{binary(), binary()}]} | {:error, :not_found}
  def get_feed_url(url, options \\ [])

  def get_feed_url(url, follow_first: true) do
    case get_feed_url(url) do
      {:candidates, [{prime_url, _title} | _]} ->
        get_feed_url(prime_url)

      result ->
        result
    end
  end

  def get_feed_url(url, []) do
    case Metalove.Fetcher.get_feed_url(url) do
      {:ok, _headers, {followed_url, _actual_url}} -> {:ok, followed_url}
      {:candidates, list} -> {:candidates, list}
      _ -> {:error, :not_found}
    end
  end

  @metalove_version Mix.Project.config()[:version]
  @doc """
  Returns the Metalove version.
  """
  @spec version :: String.t()
  def version, do: @metalove_version
end
