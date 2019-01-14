defmodule Metalove.MP3ParseTests do
  use ExUnit.Case, async: true

  alias Metalove.MediaParser

  Path.wildcard("test/files/enclosure/*.mp3")
  |> Enum.each(fn filepath ->
    @tag MP3: true
    test(Path.basename(filepath)) do
      path = unquote(filepath)
      metadata = MediaParser.extract_metadata(path)

      IO.puts("#{Path.basename(path)}: #{inspect(metadata, pretty: true)}")
    end
  end)
end
