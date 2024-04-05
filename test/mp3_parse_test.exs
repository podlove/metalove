defmodule Metalove.MP3ParseTests do
  use ExUnit.Case, async: true

  Path.wildcard("test/files/enclosure/*.mp3")
  |> Enum.each(fn filepath ->
    @tag MP3: true
    test(Path.basename(filepath)) do
      path = unquote(filepath)
      metadata = Metalove.MediaParser.extract_id3_metadata(path)

      IO.puts("#{Path.basename(path)}: #{inspect(metadata, pretty: true)}")
    end
  end)
end
