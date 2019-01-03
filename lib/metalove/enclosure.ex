defmodule Metalove.Enclosure do
  # <enclosure length="8727310" type="audio/x-m4a" url="http://example.com/podcasts/everything/AllAboutEverythingEpisode3.m4a"/>

  @derive Jason.Encoder
  defstruct url: nil,
            type: nil,
            size: nil

  def mime_type(enclosure) do
    extension =
      URI.parse(enclosure.url).path
      |> Path.extname()

    case extension do
      ".mp3" -> "audio/mp3"
      ".mp4" -> "audio/mp4"
      ".m4a" -> "audio/mp4"
      _ -> "audio"
    end
  end
end
