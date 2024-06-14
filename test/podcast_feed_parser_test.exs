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

  test "Empty feeds have an empty enum" do
    assert {:ok, cast, episodes} =
             File.read!(unquote("test/files/feed/medienkuh_without_enclosure_tags.xml"))
             |> PodcastFeedParser.parse()

    assert length(episodes) == 0
  end
end
