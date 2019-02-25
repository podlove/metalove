defmodule MetalovePodcastFeedTest do
  use ExUnit.Case

  # Just testing the internal spread_list function
  test "spread" do
    assert Metalove.PodcastFeed.spread_list([1, 2], 10) == [[1], [2]]
    assert Metalove.PodcastFeed.spread_list([1, 2], 1) == [[1, 2]]
    assert Metalove.PodcastFeed.spread_list(1..4, 2) == [[1, 3], [2, 4]]
    assert Metalove.PodcastFeed.spread_list(1..4, 2) == [[1, 3], [2, 4]]
    assert Metalove.PodcastFeed.spread_list(1..3, 2) == [[1, 3], [2]]
    assert Metalove.PodcastFeed.spread_list(1..7, 3) == [[1, 4, 7], [2, 5], [3, 6]]
  end
end
