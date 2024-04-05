defmodule Metalove.PodcastFeedParserTest do
  use ExUnit.Case, async: true
  alias Metalove.PodcastFeedParser

  doctest PodcastFeedParser

  Path.wildcard("test/files/feed/*")
  |> Enum.each(fn filepath ->
    test(Path.basename(filepath)) do
      assert {:ok, cast, _episodes} =
               File.read!(unquote(filepath))
               |> PodcastFeedParser.parse()

      IO.inspect(cast[:title])
    end
  end)
end
