defmodule Metalove.Fetcher do
  def fetch(url) do
    try do
      case HTTPoison.get(url, headers(), options()) do
        {:ok, %HTTPoison.Response{status_code: 200, body: body, headers: headers}} ->
          {:ok, body, headers}

        {:ok, %HTTPoison.Response{status_code: 304}} ->
          :notmodified

        {:ok, %HTTPoison.Response{status_code: 404}} ->
          {:error, 404}

        {:error, %HTTPoison.Error{reason: reason}} ->
          {:error, reason}
      end
    rescue
      ArgumentError -> {:error, :ArgumentError}
    end
  end

  def fetch_and_follow(url), do: fetch_and_follow(url, {url, 10})

  defp fetch_and_follow(url, {candidate_url, remaining_redirects}) do
    try do
      case HTTPoison.get(url, [],
             ssl: [{:versions, [:"tlsv1.2"]}],
             timeout: 10_000,
             recv_timeout: 10_000
           ) do
        {:ok, %HTTPoison.Response{status_code: 200, body: body, headers: headers}} ->
          {:ok, body, headers, {candidate_url, url}}

        {:ok, %HTTPoison.Response{status_code: status_code, headers: headers}}
        when status_code in [301, 302, 307, 308] ->
          if remaining_redirects > 0 do
            next_url = get_location_header(headers)
            candidate_url = if status_code in [301, 308], do: next_url, else: candidate_url
            fetch_and_follow(next_url, {candidate_url, remaining_redirects - 1})
          else
            {:error, "Too many redirects"}
          end

        {:ok, %HTTPoison.Response{status_code: 304}} ->
          :notmodified

        {:ok, %HTTPoison.Response{status_code: 404}} ->
          {:error, 404}

        {:error, %HTTPoison.Error{reason: reason}} ->
          {:error, reason}
      end
    rescue
      ArgumentError -> {:error, :ArgumentError}
    end
  end

  defp get_location_header(headers) do
    for {key, value} <- headers, String.downcase(key) == "location" do
      value
    end
  end

  def headers do
    %{}
  end

  def options do
    [
      follow_redirect: true,
      max_redirect: 10,
      ssl: [{:versions, [:"tlsv1.2"]}],
      timeout: 10_000,
      recv_timeout: 10_000
    ]
  end
end
