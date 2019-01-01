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
  def get_podcast(url, options \\ [])

  def get_podcast(url, follow_first: true) do
    case get_podcast(url) do
      {:ok, :candidates, [{prime_url, _title} | _]} ->
        get_podcast(prime_url)

      result ->
        result
    end
  end

  def get_podcast("http" <> _ = url, []) do
    # IO.inspect(url, label: "get_podcast")

    case Metalove.Fetcher.fetch_and_follow(url) do
      {:ok, content, _header, {followed_url, actual_url}} ->
        tree = Floki.parse(content)

        feed_urls =
          case Floki.find(tree, "rss") do
            [] ->
              feed_url_from_contenttree(tree)

            #              |> IO.inspect()

            _ ->
              [{followed_url, "Entered URL"}]
          end
          # ensure relative links also work fine
          #          |> IO.inspect(label: "input to merge with (#{inspect(actual_url)})")
          |> Enum.map(fn {url, title} -> {URI.merge(actual_url, url) |> to_string(), title} end)

        case feed_urls do
          [{url, _title}] ->
            {:ok, Metalove.Podcast.new(url), url}

          [] ->
            {:error, :no_podcast_found_at_url, followed_url}

          list ->
            {:ok, :candidates,
             list
             |> Enum.sort_by(fn
               {url, title} ->
                 cond do
                   url =~ ~r/mp3/i or title =~ ~r/mp3/i -> -3
                   url =~ ~r/mp4|m4a/i or title =~ ~r/mp4|m4a/i -> -2
                   url =~ ~r/audio|podcast/i or title =~ ~r/audio|podcast/i -> -1
                   true -> 0
                 end
             end)}
        end

      _ ->
        {:error, :no_podcast_found_at_url, url}
    end
  end

  # if we didn't match before, prepend http
  def get_podcast(url, []) do
    get_podcast("http://" <> url)
  end

  defp feed_url_from_contenttree(tree) do
    # first just get the header metadata links that represent feeds
    link_feeds =
      tree
      |> Floki.find("[type='application/rss+xml']")
      |> Enum.map(fn e ->
        {hd(Floki.attribute(e, "href")),
         case Floki.attribute(e, "title") do
           [] -> ""
           list when is_list(list) -> hd(list)
         end}
      end)

    case link_feeds do
      [one_result] ->
        [one_result]

      # also return all hrefs in the document as candidates if we have more than one
      link_feeds ->
        link_feeds ++
          (tree
           |> Floki.find("a")
           #           |> IO.inspect(label: "links")
           |> Enum.filter(fn c ->
             case Floki.attribute(c, "href") do
               [url] -> url =~ ~r/\.rss|\.atom|feed/i
               _ -> false
             end
           end)
           |> Enum.map(fn e -> {hd(Floki.attribute(e, "href")), Floki.text(e)} end))
    end
  end
end
