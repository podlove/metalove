defmodule Mix.Tasks.Ml.Chapter do
  use Mix.Task

  @shortdoc "Extract simple chapter information from a ID3 tagged mp3 file"

  @moduledoc """
  Extract chapter information from an ID3 tagged mp3 file.

      mix ml.chapter BASE_URL MP3_FILEPATH

  If the chapters contain images, they will be written to IMG_OUTPUT_BASEFILEPATH. They will be referenced in the generated simple chapter XML with the BASE_URL. The path of the BASE_URL will be appended to the base path of the mp3 file. E.g.

      mix ml.chapter --base_url https://fanboys.fm/images/FAN356 ~/Documents/Podcasts/Fanboys/FAN356.mp3

  Will output the XML for simple chapters, and will store all found images into ~/Documents/Podcasts/Fanboys/images/FAN356/ChapterXXX.jpeg

  ## Options

    * `--debug` - output the raw parsed ID3 information for debugging

  """

  @switches [debug: :boolean, base_url: :string]

  def run(argv) do
    case parse_opts(argv) do
      {opts, [path]} ->
        image_path_base = "/tmp"
        image_url_base = "assets/chapter_images"

        metadata = Metalove.MediaParser.extract_metadata(path)

        # IO.puts("#{Path.basename(path)}: #{inspect(metadata, pretty: true)}")

        transformed_tags = Metalove.Enclosure.transform_id3_tags(metadata[:id3][:tags])

        if opts[:debug] do
          IO.puts("#{Path.basename(path)}: #{inspect(transformed_tags, pretty: true)}")
        end

        # https://podlove.org/simple-chapters/

        chapter_tags =
          transformed_tags[:chapters]
          |> Enum.with_index(1)
          |> Enum.map(fn {chapter, index} ->
            XmlBuilder.element(
              "psc:chapter",
              case chapter[:image] do
                image_map when is_map(image_map) ->
                  image_basename =
                    "Chapter#{String.pad_leading(to_string(index), 3, "000")}.#{
                      hd(:mimerl.mime_to_exts(image_map[:type]))
                    }"

                  image_url_path = Path.join([image_url_base, image_basename])
                  image_filename = Path.join([image_path_base, image_url_path])

                  File.mkdir_p(Path.dirname(image_filename))
                  File.write!(image_filename, image_map[:data])

                  image_url = URI.merge("//yourserver", image_url_path)

                  Map.put(chapter, :image, image_url)

                _ ->
                  chapter
              end
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

      # IO.puts("Images written to #{Path.join([image_path_base, image_url_base])}")

      {opts, _} ->
        IO.inspect(opts, pretty: true)
        Mix.Tasks.Help.run(["ml.chapter"])

      _ ->
        Mix.Tasks.Help.run(["ml.chapter"])
    end
  end

  defp parse_opts(argv) do
    case OptionParser.parse(argv, strict: @switches) do
      {opts, argv, []} ->
        {opts, argv}

      {_opts, _argv, [switch | _]} ->
        Mix.raise("Invalid option: " <> switch_to_string(switch))
    end
  end

  defp switch_to_string({name, nil}), do: name
  defp switch_to_string({name, val}), do: name <> "=" <> val
end
