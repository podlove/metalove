# Metalove

[Online Documentation](https://hexdocs.pm/metalove).
[Github Changelog](https://github.com/podlove/metalove/blob/master/CHANGELOG.md).

Metalove is an Elixir Application to scrape podcast RSS feeds to extract and provide as much of the available metadata as possible. This includes relevant ID3 tag parsing to extract chapter, link and image metadata.

Metalove is intended to be a stateful live repository caching the scraped data. A one shot mode to just get one specific feed/metadata is also provided.

[Changelog](changelog.html)

## Basic Usage

Use the main Metalove module to trigger scraping of the urls you like. Then use the hierarchy of structs/modules to access them. 

A `Metalove.Podcast` can reference many `Metalove.PodcastFeed`s which in turn have `Metalove.Episode`s with `Metalove.Enclosure`s. Once scraped, `PodcastFeed`s and their `Episode`s can be fetched using their corresponding `get_…` functions.

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

## Mix Tasks

### `ml.chapter`

Parses the ID3 tag of an mp3 url or file, writes out the images and the podlove simple chapter tags. E.g.

```bash
$ mix ml.chapter --base-url http://atp.fm/img/chapter/atp312/ -o /tmp http://traffic.libsyn.com/atpfm/atp312.mp3 --formats psc,json,mp4chaps
Extracted: /tmp/Chapter01.png
Extracted: /tmp/Chapter03.jpeg
Extracted: /tmp/Chapter05.jpeg
Extracted: /tmp/Chapter06.jpeg
Extracted: /tmp/Chapter07.jpeg
Found: 15 Chapters, 12 URLs and 5 Chapter Images
Wrote: psc to /tmp/Chapters.psc.xml
Wrote: json to /tmp/ChaptersFragment.json
Wrote: mp4chaps to /tmp/Chapters.mp3chaps.txt

psc:
<?xml version="1.0" encoding="UTF-8"?>
<psc:chapters version="1.2" xmlns:psc="http://podlove.org/simple-chapters">
  <psc:chapter start="00:00:00.000" title="ATP_progrm_chptr()" image="http://atp.fm/img/chapter/atp312/Chapter01.png"/>
  <psc:chapter start="00:09:12.500" title="Follow-up: Apple-Facebook" href="https://techcrunch.com/2019/01/31/mess-with-the-cook/"/>
  <psc:chapter start="00:12:12.000" title="Follow-up: FaceTime bug" href="http://www.loopinsight.com/2019/02/05/high-level-apple-exec-flies-to-tucson-to-meet-with-14-year-old-who-discovered-facetime-flaw/" image="http://atp.fm/img/chapter/atp312/Chapter03.jpeg"/>
  <psc:chapter start="00:14:54.979" title="Sponsor: Eero (code ATP)" href="https://eero.com/"/>
  <psc:chapter start="00:16:44.107" title='USB-C "MagSafe"' href="https://amzn.to/2t6fibm" image="http://atp.fm/img/chapter/atp312/Chapter05.jpeg"/>
  <psc:chapter start="00:20:43.000" title="USB-C LED charging cable" href="http://www.amazon.com/dp/B07CHJYPCC/?tag=marcoorg-20" image="http://atp.fm/img/chapter/atp312/Chapter06.jpeg"/>
  <psc:chapter start="00:22:01.500" title="Screen-protector update" href="https://paperlike.com/" image="http://atp.fm/img/chapter/atp312/Chapter07.jpeg"/>
  <psc:chapter start="00:27:20.500" title="Sponsor: Molekule (code ATP)" href="https://molekule.com/"/>
  <psc:chapter start="00:29:02.500" title="Ahrendts leaving Apple" href="https://www.apple.com/newsroom/2019/02/apple-names-deirdre-obrien-senior-vice-president-of-retail-and-people/"/>
  <psc:chapter start="01:12:09.331" title="Sponsor: Squarespace (code ATP)" href="https://squarespace.com/atp"/>
  <psc:chapter start="01:13:31.500" title="#askatp: Hard-drive brands" href="https://www.backblaze.com/blog/2018-hard-drive-failure-rates/"/>
  <psc:chapter start="01:21:13.500" title="#askatp: Reopening windows"/>
  <psc:chapter start="01:26:41.500" title="#askatp: Gimlet-Spotify" href="https://newsroom.spotify.com/2019-02-06/audio-first/"/>
  <psc:chapter start="01:46:40.500" title="Ending theme" href="http://jonathanmann.net/"/>
  <psc:chapter start="01:47:43.500" title="Gas station update"/>
</psc:chapters>

json:
[{"start":"00:00:00.000","title":"ATP_progrm_chptr()","image":"http://atp.fm/img/chapter/atp312/Chapter01.png"},{"start":"00:09:12.500","title":"Follow-up: Apple-Facebook","href":"https://techcrunch.com/2019/01/31/mess-with-the-cook/"},{"start":"00:12:12.000","title":"Follow-up: FaceTime bug","href":"http://www.loopinsight.com/2019/02/05/high-level-apple-exec-flies-to-tucson-to-meet-with-14-year-old-who-discovered-facetime-flaw/","image":"http://atp.fm/img/chapter/atp312/Chapter03.jpeg"},{"start":"00:14:54.979","title":"Sponsor: Eero (code ATP)","href":"https://eero.com/"},{"start":"00:16:44.107","title":"USB-C \"MagSafe\"","href":"https://amzn.to/2t6fibm","image":"http://atp.fm/img/chapter/atp312/Chapter05.jpeg"},{"start":"00:20:43.000","title":"USB-C LED charging cable","href":"http://www.amazon.com/dp/B07CHJYPCC/?tag=marcoorg-20","image":"http://atp.fm/img/chapter/atp312/Chapter06.jpeg"},{"start":"00:22:01.500","title":"Screen-protector update","href":"https://paperlike.com/","image":"http://atp.fm/img/chapter/atp312/Chapter07.jpeg"},{"start":"00:27:20.500","title":"Sponsor: Molekule (code ATP)","href":"https://molekule.com/"},{"start":"00:29:02.500","title":"Ahrendts leaving Apple","href":"https://www.apple.com/newsroom/2019/02/apple-names-deirdre-obrien-senior-vice-president-of-retail-and-people/"},{"start":"01:12:09.331","title":"Sponsor: Squarespace (code ATP)","href":"https://squarespace.com/atp"},{"start":"01:13:31.500","title":"#askatp: Hard-drive brands","href":"https://www.backblaze.com/blog/2018-hard-drive-failure-rates/"},{"start":"01:21:13.500","title":"#askatp: Reopening windows"},{"start":"01:26:41.500","title":"#askatp: Gimlet-Spotify","href":"https://newsroom.spotify.com/2019-02-06/audio-first/"},{"start":"01:46:40.500","title":"Ending theme","href":"http://jonathanmann.net/"},{"start":"01:47:43.500","title":"Gas station update"}]

mp4chaps:
00:00:00.000 ATP_progrm_chptr()
00:09:12.500 Follow-up: Apple-Facebook <https://techcrunch.com/2019/01/31/mess-with-the-cook/>
00:12:12.000 Follow-up: FaceTime bug <http://www.loopinsight.com/2019/02/05/high-level-apple-exec-flies-to-tucson-to-meet-with-14-year-old-who-discovered-facetime-flaw/>
00:14:54.979 Sponsor: Eero (code ATP) <https://eero.com/>
00:16:44.107 USB-C "MagSafe" <https://amzn.to/2t6fibm>
00:20:43.000 USB-C LED charging cable <http://www.amazon.com/dp/B07CHJYPCC/?tag=marcoorg-20>
00:22:01.500 Screen-protector update <https://paperlike.com/>
00:27:20.500 Sponsor: Molekule (code ATP) <https://molekule.com/>
00:29:02.500 Ahrendts leaving Apple <https://www.apple.com/newsroom/2019/02/apple-names-deirdre-obrien-senior-vice-president-of-retail-and-people/>
01:12:09.331 Sponsor: Squarespace (code ATP) <https://squarespace.com/atp>
01:13:31.500 #askatp: Hard-drive brands <https://www.backblaze.com/blog/2018-hard-drive-failure-rates/>
01:21:13.500 #askatp: Reopening windows
01:26:41.500 #askatp: Gimlet-Spotify <https://newsroom.spotify.com/2019-02-06/audio-first/>
01:46:40.500 Ending theme <http://jonathanmann.net/>
01:47:43.500 Gas station update
```

### `ml.podcast`

Output a human friendly summary for the podcast found at the url given.

```bash
$ mix ml.podcast http://wtfpod.libsyn.com/rss

       ID: wtfpod.com
Main Feed: http://wtfpod.libsyn.com/rss

          Subtitle: Get all your WTF needs at wtfpod.com
           Summary: Comedian Marc Maron is tackling the most complex philosophical question of our day - WTF? He'll get to the bottom of it with help from comedian friends, celebrity guests and the voices in his own head.
       Description: Comedian Marc Maron is tackling the most complex philosophical question of our day - WTF? He'll get to the bottom of it with help from comedian friends, celebrity guests and the voices in his own head.
             Cover: http://static.libsyn.com/p/assets/6/c/a/3/6ca38c2fefa1e989/WTF_-_new_larger_cover.jpg
Episodes available: 60

S01E997: Episode 997 - Andrea Savage (01:24:17|2019-02-25)
   Andrea Savage visits the garage to talk about her show I'm Sorry, life with agents, Jason Mantzoukas, and being cut from The Groundlings. http://wtfpod.libsyn.com/episode-997-andrea-savage
 .mp3: http://traffic.libsyn.com/wtfpod/WTF_-_EPISODE_997_ANDREA_SAVAGE.mp3?dest-id=14434 (24.42 MB)

S01E996: Episode 996 - Jon Bernthal (01:40:59|2019-02-21)
   Jon Bernthal talks about The Punisher, The Walking Dead, Martin Scorsese, and how he went from heading down a bad path in life to salvation by way of acting. http://wtfpod.libsyn.com/episode-996-jon-bernthal
 .mp3: http://traffic.libsyn.com/wtfpod/WTF_-_EPISODE_996_JON_BERNTHAL.mp3?dest-id=14434 (29.2 MB)
…
```

## Known issues

* Metalove currently caches all http requests and state quite ridiculously, and does not reevaluate them their own. As workaround until that is done correctly the `Metalove.purge/0` exists.
* Metalove currently logs a lot.

## License

Metalove is released under the MIT license - see the [LICENSE.txt](//github.com/Podlove/metalove/LICENSE.txt) file.

## Installation

The package can be installed by adding `metalove` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:metalove, "~> 0.3"}
  ]
end
```
