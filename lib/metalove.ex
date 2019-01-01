defmodule Metalove do
  @moduledoc """
  Documentation for Metalove.
  """

  @doc """

  ## Examples

      iex> Metalove.get_podcast("freakshow.fm")
      :world

  """
  def get_podcast(url) do
    case Metalove.Fetcher.fetch_and_follow(url) do
      {:ok, content, header, {followed_url, _actual_url}} ->
        tree = Floki.parse(content)

        feed_urls =
          case Floki.find(tree, "rss") do
            [] ->
              IO.inspect(feed_url_from_contenttree(tree))

            _ ->
              [{followed_url, "Entered URL"}]
          end

        case feed_urls do
          [{url, _title}] ->
            {:ok, Metalove.Podcast.new(url)}

          [] ->
            {:error, :no_podcast_found_at_url}

          list ->
            {:ok, :candidates, list}
        end

      _ ->
        {:error, :no_podcast_found_at_url}
    end
  end

  defp feed_url_from_contenttree(tree) do
    # first just get the header metadata links that represent feeds
    link_feeds =
      tree
      |> Floki.find("[type='application/rss+xml']")
      |> Enum.map(fn e -> {hd(Floki.attribute(e, "href")), hd(Floki.attribute(e, "title"))} end)

    case link_feeds do
      [one_result] ->
        [one_result]

      # also return all hrefs in the document as candidates if we have more than one
      link_feeds ->
        link_feeds ++
          (tree
           |> Floki.find("a")
           |> Enum.filter(fn c -> hd(Floki.attribute(c, "href")) =~ ~r/rss|atom|feed/i end)
           |> Enum.map(fn e -> {hd(Floki.attribute(e, "href")), Floki.text(e)} end))
    end
  end
end
