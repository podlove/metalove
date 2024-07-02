defmodule MetaloveTest do
  use ExUnit.Case

  alias Metalove.Repository

  # NOTE: integration test that requires internet
  describe "get_podcast/1" do
    test "gets feed url" do
      feed_url = "https://feeds.podlovers.org/mp3"
      first_episode_guid = "podlove-2020-07-13t19:33:45+00:00-2094546435a1a81"

      # sanity check: cache is empty
      assert {:not_found} = Repository.get({:url, feed_url})

      assert {:not_found} =
               Repository.get({:episode, feed_url, first_episode_guid})

      podcast = Metalove.get_podcast(feed_url)

      #  assert that cache was filled
      assert Repository.get({:url, feed_url}) == {:found, feed_url}

      assert {:found, %Metalove.Episode{guid: ^first_episode_guid}} =
               Repository.get({:episode, feed_url, first_episode_guid})

      #  assert some example values
      assert podcast.main_feed_url == "https://feeds.podlovers.org/mp3"

      feed = Metalove.PodcastFeed.get_by_feed_url(podcast.main_feed_url)

      assert feed.title == "Podlovers"
      assert feed.link == "https://podlovers.org/"
      assert Enum.count(feed.episodes) > 0

      first_episode = Metalove.Episode.get_by_episode_id(List.last(feed.episodes))

      assert first_episode.episode == "1"
      assert first_episode.title == "Wir. Müssen Reden"
    end
  end
end
