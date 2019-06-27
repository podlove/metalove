defmodule Mix.Tasks.Ml.Chapter do
  use Mix.Task

  @shortdoc "Extract simple chapter information from a ID3 tagged mp3 file"

  @moduledoc """
  Extract chapter information from an ID3 tagged mp3 file.

      mix ml.chapter --base-url BASE_URL MP3_FILEPATH_OR_URL

  If the chapters contain images, they will be written to the path of the source file appended by the path of the URL. They will be referenced in the generated simple chapter XML with the BASE_URL. The path of the BASE_URL will be appended to the base path of the mp3 file. E.g.

      mix ml.chapter --base-url https://fanboys.fm/chapters/fan356 --formats psc,json ~/Documents/Podcasts/Fanboys/FAN356.mp3

  Will output the XML for simple chapters, and will store all found images into `~/Documents/Podcasts/Fanboys/images/FAN356/ChapterXX.jpeg`. In addition to outputting the psc and json format to stdout they will be written to `Chapters.psc.xml` and `ChaptersFragment.json` accordingly.

  Will also write the chapters as PSCChaptersFragment.psc and PodloveWebPlayerChaptersFragment.json

  ## Options


    * `--base-url URL` - if given will add image_url hrefs to the chapters with images and save the images found in the ID3 tag chapters as well as the cover art to the directory of the source file appended by the path of the url.
    * `--output PATH` - if given will save encountered images into that path instead.
    * `--debug` - output the raw parsed ID3 information for debugging.
    * `--formats FORMATS` - psc, json or mp4chaps. Defaults to psc only. Allows multiple comma separated.
    * `--stdout-formats FORMATS` - formats to write to stdout. Defaults to value of `--formats`

  """

  @switches [
    base_url: :string,
    debug: :boolean,
    output: :string,
    formats: :string,
    stdout_formast: :string
  ]
  @aliases [d: :debug, o: :output]

  defp split_format(format_string, default) when is_binary(format_string) do
    format_string
    |> String.split(",")
    |> Enum.reduce([], fn
      "mp4chaps", acc ->
        [:mp4chaps | acc]

      "json", acc ->
        [:json | acc]

      "psc", acc ->
        [:psc | acc]

      format, acc ->
        Mix.Shell.IO.error([
          :yellow,
          "Warning: ",
          :reset,
          "Format #{format} not recognized."
        ])

        acc
    end)
    |> Enum.reverse()
    |> case do
      [] -> default
      other -> other
    end
  end

  defp split_format(_, default), do: default

  defp prepare_opts(opts, path_or_url) do
    formats = split_format(opts[:formats], [:psc])
    stdout_formats = split_format(opts[:stdoout_formats], formats)

    image_url_path =
      case opts[:base_url] do
        nil -> "/"
        url -> URI.parse(url).path
      end

    media_url =
      case path_or_url do
        <<"http", _::binary>> = media_url -> media_url
        _ -> nil
      end

    base_output_path =
      if media_url do
        Path.dirname(URI.parse(media_url).path)
      else
        Path.dirname(path_or_url)
      end
      |> List.wrap()
      |> List.insert_at(0, System.tmp_dir!())
      |> Path.join()

    chapter_images_output_path =
      case image_url_path do
        nil -> nil
        url_path -> Path.join(base_output_path, url_path)
      end

    Map.merge(opts, %{
      image_url_path: image_url_path,
      output: opts[:output] || chapter_images_output_path,
      media_url: media_url,
      formats: formats,
      stdout_formats: stdout_formats
    })
  end

  alias Chapters.Chapter

  @impl true
  @doc false
  def run(argv) do
    case parse_opts(argv) do
      {opts, [path]} ->
        opts = prepare_opts(Map.new(opts), path)

        metadata =
          case opts[:media_url] do
            nil ->
              try do
                Metalove.MediaParser.extract_id3_metadata(path)
              rescue
                e in File.Error ->
                  Mix.Shell.IO.error([
                    "error: ",
                    :reset,
                    "Error reading file #{e.path} reason: #{e.reason}."
                  ])

                  System.halt(1)
              end

            url ->
              # Bring up Metalove
              Mix.Project.get!()
              Mix.Task.run("loadpaths")
              Mix.Task.run("run")

              Metalove.Enclosure.fetch_id3_metadata(url)
          end

        if opts[:debug], do: IO.puts("#{Path.basename(path)}: #{inspect(metadata, pretty: true)}")

        metadata_map = Metalove.Enclosure.transform_id3_tags(metadata[:tags])

        if opts[:debug],
          do: IO.puts("#{Path.basename(path)}: #{inspect(metadata_map, pretty: true)}")

        #          IO.puts("#{Path.basename(path)}: #{inspect(transformed_tags, pretty: true)}")

        with image_map <- metadata_map[:cover_art],
             path <- opts[:output] do
          write_image(image_map, path, "Cover")
        end

        # https://podlove.org/simple-chapters/

        case extract_chapters(metadata_map, opts) do
          [] ->
            Mix.Shell.IO.error([
              "error: ",
              :reset,
              "Could not extract chapters from #{Path.basename(path)}."
            ])

          chapters ->
            if opts[:debug] do
              IO.puts("#{inspect(chapters, pretty: true)}")
              pseudo_flush_stdout()
            end

            Mix.Shell.IO.error([
              :green,
              "Found:",
              :reset,
              " #{length(chapters)} Chapters, #{Enum.count(chapters, & &1.href)} URLs and #{
                Enum.count(chapters, & &1.image)
              } Chapter Images"
            ])

            with path <- opts[:output],
                 formats <- opts[:formats],
                 stdout_formats <- opts[:stdout_formats] do
              formats
              |> Enum.each(fn format ->
                filename =
                  case format do
                    :psc -> "Chapters.psc.xml"
                    :mp4chaps -> "Chapters.mp3chaps.txt"
                    :json -> "ChaptersFragment.json"
                  end

                data = Chapters.encode(chapters, format)

                filepath = Path.join(path, filename)

                File.write!(filepath, data)

                Mix.Shell.IO.error([
                  :green,
                  "Wrote:",
                  :reset,
                  " ",
                  :bright,
                  "#{format}",
                  :reset,
                  " to ",
                  :bright,
                  "#{filepath}"
                ])
              end)

              stdout_formats
              |> Enum.each(fn format ->
                Mix.Shell.IO.error([
                  :bright,
                  :green,
                  "\n#{format}:"
                ])

                Chapters.encode(chapters, format) |> IO.puts()

                # Without the additional small delay, the error output sometimes interleaves with the other output
                pseudo_flush_stdout()
              end)
            end
        end

      _ ->
        Mix.Tasks.Help.run(["ml.chapter"])
    end
  end

  defp write_image(image_map, path, basename) do
    path = Path.join(path, basename <> ".#{hd(:mimerl.mime_to_exts(image_map[:type]))}")
    File.mkdir_p(Path.dirname(path))
    File.write!(path, image_map[:data])
    path
  end

  defp extract_chapters(metadata_map, opts) do
    (metadata_map[:chapters] || [])
    |> Enum.with_index(1)
    |> Enum.map(fn {chapter, index} ->
      chapter
      |> Enum.map(fn
        {:image = key, image_map} when is_map(image_map) ->
          case opts[:output] do
            nil ->
              {key, nil}

            path ->
              filepath =
                write_image(
                  image_map,
                  path,
                  "Chapter#{String.pad_leading(to_string(index), 2, "00")}"
                )

              Mix.Shell.IO.error([:green, "Extracted:", :reset, " ", filepath])

              URI.merge(
                opts[:base_url] || "//use_base_url_option",
                Path.join(opts[:image_url_path], Path.basename(filepath))
              )
              |> to_string
              |> (&{key, &1}).()
          end

        {key, ""} ->
          {key, nil}

        {key, value} ->
          {key, value}
      end)
      |> Map.new()
      |> Map.put(:index, index)
    end)
    |> Enum.map(fn chapter ->
      %Chapter{
        start: normal_playtime_to_ms(chapter[:start]),
        title: chapter[:title] || "#{chapter[:index]}",
        href: chapter[:href],
        image: chapter[:image]
      }
    end)
  end

  alias Chapters.Parsers.Normalplaytime.Parser, as: NPT

  defp normal_playtime_to_ms(playtime) when is_binary(playtime) do
    NPT.parse_total_ms(playtime) || 0
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

  defp pseudo_flush_stdout() do
    :timer.sleep(50)
  end
end
