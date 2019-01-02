defmodule Metalove do
  @moduledoc """
  Documentation for Metalove.
  """

  @doc """

  ## Examples

      iex> {:ok, :candidates, list} = Metalove.get_podcast("freakshow.fm")
      iex> hd(list)
      {"http://freakshow.fm/feed/mp3", "Podcast Feed: Freak Show (MP3 Audio)"}
  """

  def get_feed_url(url, options \\ [])

  def get_feed_url(url, follow_first: true) do
    case get_feed_url(url) do
      {:ok, :candidates, [{prime_url, _title} | _]} ->
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
end
