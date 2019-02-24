# Metalove

Metalove is an Elixir Application to scrape podcast RSS feeds to extract and provide as much of the available metadata as possible. This includes relevant ID3 tag parsing to extract chapter, link and image metadata.

Metalove is intended to be a stateful live repository caching the scraped data. A one shot mode to just get one specific feed/metadata is also provided.

## Installation

The package can be installed
by adding `metalove` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:metalove, "~> 0.2.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/metalove](https://hexdocs.pm/metalove).

## Basic Usage

Defines a hierarchy of structs. A `Metalove.Podcast` can reference many `Metalove.PodcastFeed`s which in turn have `Metalove.Episode`s with `Metalove.Enclosure`s. Once scraped, `PodcastFeed`s and their `Episode`s can be fetched using their corresponding `get_…` functions.

```elixir
iex> feed_or_website_url = "forschergeist.de"
iex> podcast = Metalove.get_podcast(feed_or_website_url)
%Metalove.Podcast{
	created_at: #DateTime<2019-02-23 13:09:48.632101Z>,
	feed_urls: ["http://forschergeist.de/feed/opus/",
		"http://forschergeist.de/feed/oga/", 
		"http://forschergeist.de/feed/m4a/",
		"http://forschergeist.de/feed/mp3/"],
	id: "forschergeist.de",
	main_feed_url: "http://forschergeist.de/feed/mp3/",
	updated_at: #DateTime<2019-02-23 13:23:10.917299Z>
}
	
iex> feed = Metalove.PodcastFeed.get_by_feed_url(podcast.main_feed_url)
iex> most_recent_episode = Metalove.Episode.get_by_episode_id(hd(feed.episodes))
```

## License

Metalove is released under the MIT license - see the [LICENSE.txt](LICENSE.txt) file.