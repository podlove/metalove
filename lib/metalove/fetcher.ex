defmodule Metalove.Fetcher do
  def fetch_and_follow(url),
    do: fetch_and_follow_p(url, {url, 10})

  #     |> IO.inspect(label: "fetch_and_follow_result #{inspect(url)}")

  defp fetch_and_follow_p(url, {candidate_url, remaining_redirects}) do
    try do
      HTTPoison.get(url, headers(), options())
      #     |> IO.inspect(label: "Fetch (#{remaining_redirects})")
      |> case do
        {:ok, %HTTPoison.Response{status_code: 200, body: body, headers: headers}} ->
          {:ok, body, headers, {candidate_url, url}}

        {:ok, %HTTPoison.Response{status_code: status_code, headers: headers}}
        when status_code in [301, 302, 307, 308] ->
          if remaining_redirects > 0 do
            next_url = URI.merge(url, get_header(headers, "location")) |> to_string
            candidate_url = if status_code in [301, 308], do: next_url, else: candidate_url
            fetch_and_follow_p(next_url, {candidate_url, remaining_redirects - 1})
          else
            {:error, "Too many redirects"}
          end

        {:ok, %HTTPoison.Response{status_code: 404}} ->
          {:error, 404, {candidate_url, url}}

        {:error, %HTTPoison.Error{reason: reason}} ->
          {:error, reason, {candidate_url, url}}
      end
    rescue
      ArgumentError -> {:error, :ArgumentError}
    end
  end

  defp get_header(headers, key) do
    key = key |> String.downcase()

    headers
    # According to https://www.w3.org/Protocols/rfc2616/rfc2616-sec4.html#sec4.2 http headers are to be treated case insensitive
    |> Enum.find(fn {k, _value} -> String.downcase(k) == key end)
    |> case do
      {_key, value} -> value
    end
  end

  defp headers do
    %{}
  end

  defp options do
    [
      ssl: [{:versions, [:"tlsv1.2"]}],
      timeout: 10_000,
      recv_timeout: 10_000
    ]
  end

  def get_feed_url(url) do
    url = sanitize_url(url)
    get_feed_url_p(url, {url, 10})
  end

  defp get_feed_url_p(url, {candidate_url, remaining_redirects}) do
    # IO.inspect(binding())
    #  try do
    HTTPoison.head(url, [], options())
    #     |> IO.inspect(label: "Fetch (#{remaining_redirects})")
    |> case do
      {:ok, %HTTPoison.Response{status_code: 200, body: _body, headers: headers}} ->
        headers
        |> get_header("content-type")
        |> String.downcase()
        |> case do
          "text/html" <> _ ->
            {:ok, body, _headers, {candidate_url, url}} =
              fetch_and_follow_p(url, {url, remaining_redirects})

            body
            |> Floki.parse()
            |> feed_urls_from_contenttree()
            |> case do
              [] -> {:error, :not_found, {candidate_url, url}}
              [{url, _title}] -> get_feed_url_p(url, {url, remaining_redirects - 1})
              candidates -> {:candidates, sort_feed_candidates(candidates)}
            end

          "text/xml" <> _ ->
            {:ok, headers, {candidate_url, url}}

          "application/rss+xml" <> _ ->
            {:ok, headers, {candidate_url, url}}

          content_format ->
            IO.inspect(headers, label: "found headers for content format (#{content_format})")
            {:error, :uknown_content_format, content_format, {candidate_url, url}}
        end

      {:ok, %HTTPoison.Response{status_code: status_code, headers: headers}}
      when status_code in [301, 302, 307, 308] ->
        if remaining_redirects > 0 do
          next_url = URI.merge(url, get_header(headers, "location")) |> to_string
          candidate_url = if status_code in [301, 308], do: next_url, else: candidate_url
          get_feed_url_p(next_url, {candidate_url, remaining_redirects - 1})
        else
          {:error, "Too many redirects"}
        end

      {:ok, %HTTPoison.Response{status_code: 404}} ->
        {:error, 404, {candidate_url, url}}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason, {candidate_url, url}}
    end

    #  rescue
    #   ArgumentError -> {:error, :ArgumentError}
    # end
  end

  defp sanitize_url("http" <> _ = url), do: url
  defp sanitize_url(url), do: "http://" <> url

  defp feed_urls_from_contenttree(tree) do
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

  defp sort_feed_candidates(list) do
    list
    |> Enum.sort_by(fn
      {url, title} ->
        cond do
          url =~ ~r/mp3/i or title =~ ~r/mp3/i -> -3
          url =~ ~r/mp4|m4a/i or title =~ ~r/mp4|m4a/i -> -2
          url =~ ~r/audio|podcast/i or title =~ ~r/audio|podcast/i -> -1
          true -> 0
        end
    end)
  end
end
