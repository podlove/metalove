defmodule Mix.Tasks.Ml.Podcast do
  use Mix.Task

  @shortdoc "Ingest all metadata found for a given podcast (website) url."

  @moduledoc """
  Output a human friendly summary for the podcast found at the url.

      mix ml.podcast atp.fm

  * `--debug` - output the raw parsed ID3 information for debugging.

  """

  @switches [debug: :boolean]
  @aliases [d: :debug]

  @impl true
  def run(args) do
    case parse_opts(args) do
      {opts, [url]} ->
        Mix.Project.get!()
        Mix.Task.run("loadpaths")
        Mix.Task.run("run")

        podcast = Metalove.get_podcast(url)

        feed =
          Metalove.PodcastFeed.get_by_feed_url_await_all_pages(podcast.main_feed_url, 120_000)

        opts = Map.new(opts)
        pretty_print(podcast, opts)
        pretty_print(feed, opts)

      _ ->
        Mix.Tasks.Help.run(["ml.podcast"])
    end
  end

  defp parse_opts(argv) do
    case OptionParser.parse(argv, strict: @switches, aliases: @aliases) do
      {opts, argv, []} ->
        {opts, argv}

      {_opts, _argv, [switch | _]} ->
        Mix.raise("Invalid option: " <> switch_to_string(switch))
    end
  end

  defp switch_to_string({name, nil}), do: name
  defp switch_to_string({name, val}), do: name <> "=" <> val

  defp pretty_print(%Metalove.Podcast{} = podcast, opts) do
    pretty_print_keylist([
      {"ID", podcast.id},
      {"Main Feed", podcast.main_feed_url}
    ])

    if opts[:debug], do: IO.inspect(podcast, pretty: true)
  end

  defp pretty_print(%Metalove.PodcastFeed{} = feed, opts) do
    if opts[:debug], do: IO.inspect(feed, pretty: true)

    pretty_print_keylist([
      {"Subtitle", feed.subtitle},
      {"Summary", feed.summary},
      {"Description", feed.description},
      {"Cover", feed.image_url},
      {"Episodes available", length(feed.episodes) |> to_string}
    ])

    feed.episodes
    |> Enum.each(fn episode_id ->
      episode = Metalove.Episode.get_by_episode_id(episode_id)
      pretty_print(episode, opts)
    end)
  end

  defp pretty_print(%Metalove.Episode{} = episode, opts) do
    if opts[:debug], do: IO.inspect(episode, pretty: true)

    season_episode =
      case {episode.season, episode.episode} do
        {nil, nil} ->
          ""

        {nil, episode} ->
          "E" <> String.pad_leading(episode, 2, ["0"]) <> ": "

        {season, nil} ->
          "S" <> String.pad_leading(season, 2, ["0"]) <> "E??: "

        {season, episode} ->
          "S" <>
            String.pad_leading(season, 2, ["0"]) <>
            "E" <> String.pad_leading(episode, 2, ["0"]) <> ": "
      end

    publish_date =
      :io_lib.format("~4..0B-~2..0B-~2..0B", [
        episode.pub_date.year,
        episode.pub_date.month,
        episode.pub_date.day
      ])
      |> IO.iodata_to_binary()

    Mix.Shell.IO.info([
      :light_black,
      season_episode,
      :reset,
      episode.title,
      :light_black,
      " (#{episode.duration}|#{publish_date})"
    ])

    if length(episode.contributors) > 0 do
      Mix.Shell.IO.info([
        "  Featuring: ",
        :cyan,
        episode.contributors
        |> Enum.map(fn c ->
          c[:name]
        end)
        |> Enum.join(", ")
      ])
    end

    Mix.Shell.IO.info([
      "   ",
      :light_black,
      episode.summary || episode.subtitle || "",
      " ",
      :reset,
      :underline,
      episode.link || ""
    ])

    # IO.inspect(Metalove.Episode.all_enclosures(episode), pretty: true)

    Metalove.Episode.all_enclosures(episode)
    |> Enum.map(fn enclosure ->
      {Path.extname(URI.parse(enclosure.url).path),
       enclosure.url <> " (#{Sizeable.filesize(enclosure.size)})"}
    end)
    |> pretty_print_keylist(7)

    Mix.Shell.IO.info([""])
  end

  defp pretty_print_keylist(keylist) do
    max_fun = fn {key, _value} ->
      key |> to_string |> String.length()
    end

    max_keylength =
      keylist
      |> Enum.max_by(max_fun)
      |> max_fun.()

    pretty_print_keylist(keylist, max_keylength + 2)
  end

  defp pretty_print_keylist([{key, value} | rest], left_indent) do
    if value do
      Mix.Shell.IO.info([
        :bright,
        :blue,
        "#{key}: " |> String.pad_leading(left_indent),
        :reset,
        value
      ])
    end

    pretty_print_keylist(rest, left_indent)
  end

  defp pretty_print_keylist([], _left_indent) do
  end
end
