defmodule Mix.Tasks.Ml.Chapter do
  use Mix.Task

  @shortdoc "Extract simple chapter information from a ID3 tagged mp3 file"

  @moduledoc """
  Extract chapter information from an ID3 tagged mp3 file.

      mix ml.chapter --base-url BASE_URL MP3_FILEPATH

  If the chapters contain images, they will be written to the path of the source file appended by the path of the URL. They will be referenced in the generated simple chapter XML with the BASE_URL. The path of the BASE_URL will be appended to the base path of the mp3 file. E.g.

      mix ml.chapter --base-url https://fanboys.fm/images/FAN356 ~/Documents/Podcasts/Fanboys/FAN356.mp3

  Will output the XML for simple chapters, and will store all found images into ~/Documents/Podcasts/Fanboys/images/FAN356/ChapterXXX.jpeg

  ## Options


    * `--base-url URL` - if given will add image_url hrefs to the chapters with images and save the images found in the ID3 tag chapters as well as the cover art to the directory of the source file appended by the path of the url.
    * `--output PATH` - if given will save encountered images into that path instead.
    * `--debug` - output the raw parsed ID3 information for debugging.

  """

  @switches [base_url: :string, debug: :boolean, output: :string]
  @aliases [d: :debug, o: :output]

  def prepare_opts(opts, path) do
    image_url_path =
      case opts[:base_url] do
        nil -> nil
        url -> URI.parse(url).path
      end

    base_output_path = Path.dirname(path)

    chapter_images_output_path =
      case image_url_path do
        nil -> nil
        url_path -> Path.join(base_output_path, url_path)
      end

    Map.merge(opts, %{
      image_url_path: image_url_path,
      output: opts[:output] || chapter_images_output_path,
      base_output_path: base_output_path
    })
  end

  def run(argv) do
    case parse_opts(argv) do
      {opts, [path]} ->
        opts = prepare_opts(Map.new(opts), path)

        metadata = Metalove.MediaParser.extract_metadata(path)

        if opts[:debug], do: IO.puts("#{Path.basename(path)}: #{inspect(metadata, pretty: true)}")

        metadata_map = Metalove.Enclosure.transform_id3_tags(metadata[:id3][:tags])

        #          IO.puts("#{Path.basename(path)}: #{inspect(transformed_tags, pretty: true)}")

        chapter_attributes = extract_chapter_attributes(metadata_map, opts)

        # https://podlove.org/simple-chapters/

        chapter_tags =
          chapter_attributes
          |> Enum.map(fn chapter_attribute_keylist ->
            XmlBuilder.element(
              "psc:chapter",
              chapter_attribute_keylist,
              nil
            )
          end)

        # IO.puts("XML source: #{inspect(chapter_tags, pretty: true)}")

        XmlBuilder.element(
          "psc:chapters",
          %{:version => "1.2", :"xmlns:psc" => "http://podlove.org/simple-chapters"},
          chapter_tags
        )
        |> XmlBuilder.generate()
        |> IO.puts()

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

  defp extract_chapter_attributes(metadata_map, opts) do
    metadata_map[:chapters]
    |> Enum.with_index(1)
    |> Enum.map(fn {chapter, index} ->
      case chapter[:image] do
        image_map when is_map(image_map) ->
          case opts[:output] do
            nil ->
              Map.delete(chapter, :image)

            path ->
              basename =
                write_image(
                  image_map,
                  path,
                  "Chapter#{String.pad_leading(to_string(index), 3, "000")}"
                )
                |> IO.inspect(label: "Extracted")
                |> Path.basename()

              URI.merge(opts[:base_url], Path.join(opts[:image_url_path], basename))
              |> to_string
              |> (&Map.put(chapter, :image, &1)).()
          end

        _ ->
          chapter
      end
      |> attributes_from_chapter_map()
    end)
  end

  defp attributes_from_chapter_map(chapter) do
    [:start, :title, :href, :image]
    |> Enum.reduce([], fn key, acc ->
      case chapter[key] do
        nil ->
          acc

        value ->
          case String.trim(value) do
            "" -> acc
            value -> List.keystore(acc, key, 0, {key, value})
          end
      end
    end)
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
end
