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
