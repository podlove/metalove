defmodule Metalove.MediaParser do
  alias Metalove.MediaParser.ID3

  def extract_metadata(filename) do
    bytes = File.read!(filename)

    %{
      size: byte_size(bytes),
      id3: ID3.parse(bytes)
    }
  end
end

defmodule Metalove.MediaParser.ID3 do
  def parse_header(binary)

  def parse_header(
        <<"ID3", version::size(8), revision::size(8), a::size(1), b::size(1), c::size(1),
          d::size(1), _ignore::size(4), rest::binary>>
      ) do
    case parse_syncsafe_integer(rest) do
      {:ok, tag_size, rest} ->
        flags =
          [a: a, b: b, c: c, d: d]
          |> Enum.reduce([], fn
            {:a, 1}, acc -> [:unsync | acc]
            {:b, 1}, acc -> [:ext_header | acc]
            {:c, 1}, acc -> [:experimental | acc]
            {:d, 1}, acc -> [:footer | acc]
            _, acc -> acc
          end)

        case byte_size(rest) do
          size when size >= tag_size ->
            {:ok, tag_size, version, revision, flags, rest}

          _ ->
            {:content_to_short, tag_size + 10}
        end

      _ ->
        :not_id3
    end
  end

  def parse_header(_), do: :not_id3

  require Logger

  def parse(content) when is_binary(content) do
    case parse_header(content) do
      {:ok, tag_size, version, revision, flags, content} ->
        result_map = %{
          version: "#{version}.#{revision}",
          flags: flags,
          tag_size: tag_size,
          tags: []
        }

        Logger.debug("ID3 Header – size:#{tag_size} v:#{result_map.version} flags:#{flags}")

        case version do
          # https://mutagen-specs.readthedocs.io/en/latest/id3/id3v2.3.html
          3 ->
            %{result_map | tags: parse_frames(content, tag_size)}

          # https://mutagen-specs.readthedocs.io/en/latest/id3/id3v2.2.html
          2 ->
            %{result_map | tags: parse_v220_frames(content, tag_size)}

          _ ->
            Logger.debug("ID3v2.#{result_map.version} not supported (yet)")
            result_map
        end

      result ->
        result
    end
  end

  def parse_frames(content) when is_binary(content), do: parse_frames(content, byte_size(content))

  def parse_frames(content, remaining_size) do
    parse_frames(content, remaining_size, [])
  end

  # Allow for padding
  def parse_frames(<<0::size(8), _rest::binary>>, _remaining_size, acc),
    do: parse_frames(<<>>, 0, acc)

  def parse_frames(<<frame_id::bytes-4, rest::binary>> = _begin, remaining_size, acc)
      when remaining_size > 10 and frame_id != <<0, 0, 0, 0>> do
    #    IO.inspect(binary_part(begin, 0, 10), label: "Frame Header:")
    #    IO.inspect("#{frame_id}", binaries: :as_strings)

    # This would be for ID3v2.4.0
    # {:ok, frame_size, rest} = parse_syncsafe_integer(rest)
    <<frame_size::32, rest::binary>> = rest
    <<frame_flags::bytes-2, rest::binary>> = rest

    # IO.puts("#{frame_id} - remaining: #{remaining_size} - frame: #{frame_size}")

    <<_::1, a::1, b::1, c::1, _::1, _::1, _::1, _::1, _::1, h::1, _::1, _::1, k::1, m::1, n::1,
      p::1>> = frame_flags

    parsed_flags =
      [a: a, b: b, c: c, h: h, k: k, m: m, n: n, p: p]
      |> Enum.reduce([], fn
        {:a, 1}, acc -> [:tag_alter_discard | acc]
        {:b, 1}, acc -> [:file_alter_discard | acc]
        {:c, 1}, acc -> [:read_only | acc]
        {:h, 1}, acc -> [:group_id | acc]
        {:k, 1}, acc -> [:zlib | acc]
        {:m, 1}, acc -> [:encrypted | acc]
        {:n, 1}, acc -> [:unsync | acc]
        {:p, 1}, acc -> [:has_data_length | acc]
        _, acc -> acc
      end)

    #    |> IO.inspect(label: "Frame Flags: ")

    remaining_size = remaining_size - 10 - frame_size
    <<frame_content::binary-size(frame_size), rest::binary>> = rest
    acc = [parse_frame(frame_id, parsed_flags, frame_content) | acc]
    parse_frames(rest, remaining_size, acc)
  end

  def parse_frames(_, remaining_size, acc) when remaining_size <= 10, do: Enum.reverse(acc)

  # Text information frames
  def parse_frame(<<"T", _::bytes-3>> = frame_id, _parsed_flags, content) do
    {String.to_atom(frame_id), parse_text_frame_content(content)}
  end

  # User definde URL link frame
  def parse_frame("WXXX", _parsed_flags, content) do
    {format, content} = take_text_format(content)
    {title, link} = take_zero_terminated_text(content, format)
    link = text_to_utf8(link, 0)

    {:WXXX, %{link: link, title: title}}
  end

  # Attached Picture
  def parse_frame("APIC", _parsed_flags, content) do
    {format, content} = take_text_format(content)
    {mime_type, content} = take_zero_terminated_text(content, format)
    <<picture_type::8, content::binary>> = content
    {description, image_data} = take_zero_terminated_text(content, format)

    # debug_write(image_data, mime_type)

    {:APIC,
     %{
       mime_type: mime_type,
       picture_type: picture_type,
       image_data: image_data,
       description: description
     }}
  end

  # Chapters: http://id3.org/id3v2-chapters-1.0
  def parse_frame("CHAP", _parsed_flags, content) do
    {element_id, content} = take_zero_terminated(content)
    <<start_time::32, end_time::32, start_offset::32, end_offset::32, rest::binary>> = content

    {:CHAP,
     %{
       element_id: element_id,
       start_time: start_time,
       end_time: end_time,
       start_offset: start_offset,
       end_offset: end_offset,
       sub_frames: parse_frames(rest)
     }}
  end

  def parse_frame("CTOC", _parsed_flags, content) do
    {element_id, content} = take_zero_terminated(content)
    # <<flags, count, _::binary>> = content
    <<_::6, top_level::1, ordered::1, content::binary>> = content
    <<entry_count::8, content::binary>> = content

    {children, content} =
      case entry_count do
        # This is not supposed to be allowed, however, hindenburg at least seems to produce it this way
        0 ->
          parse_ctoc_entries(content)

        count ->
          1..count
          |> Enum.reduce({[], content}, fn _, {acc, content} ->
            {element_id, rest} = take_zero_terminated(content)
            {[element_id | acc], rest}
          end)
      end

    descriptive = content

    {:CTOC,
     %{
       element_id: element_id,
       children: Enum.reverse(children),
       top_level: top_level != 0,
       ordered: ordered != 0,
       descriptive_data: descriptive
     }}
  end

  def parse_frame(frame_id, parsed_flags, _content), do: {frame_id, parsed_flags}

  def parse_ctoc_entries(binary) do
    parse_ctoc_entries(binary, [])
  end

  def parse_ctoc_entries(<<>>, acc), do: {acc, <<>>}

  def parse_ctoc_entries(<<"TIT2", rest::binary>>, acc), do: {acc, rest}

  def parse_ctoc_entries(binary, acc) do
    {element_id, rest} = take_zero_terminated(binary)
    parse_ctoc_entries(rest, [element_id | acc])
  end

  def parse_v220_frames(content, remaining_size),
    do: parse_v220_frames_p(content, remaining_size, [])

  def parse_v220_frames_p(<<>>, 0, acc), do: Enum.reverse(acc)

  # Allow for 0 padding
  def parse_v220_frames_p(<<0, 0, 0, _::binary>>, _, acc), do: parse_v220_frames_p(<<>>, 0, acc)

  def parse_v220_frames_p(
        <<frame_id::bytes-3, frame_size::24, rest::binary>>,
        remaining_size,
        acc
      ) do
    case remaining_size - 6 - frame_size do
      too_small when too_small <= 6 ->
        parse_v220_frames_p(<<>>, 0, acc)

      new_remaining_size ->
        <<frame_content::bytes-size(frame_size), new_content::binary>> = rest

        parse_v220_frames_p(new_content, new_remaining_size, [
          parse_v220_frame(frame_id, frame_content) | acc
        ])
    end
  end

  # Text frames
  def parse_v220_frame(<<"T", _::binary>> = frame_id, frame_content) do
    {String.to_atom(frame_id), parse_text_frame_content(frame_content)}
  end

  def parse_v220_frame("COM", <<format, language::bytes-3, twostrings::binary>>) do
    {description, text} = take_zero_terminated(twostrings)

    {:COM,
     %{
       description: description |> text_to_utf8(format),
       text: text |> text_to_utf8(format) |> String.trim_trailing(<<0>>),
       language: language
     }}
  end

  def parse_v220_frame("PIC", content) do
    {format, content} = take_text_format(content)
    <<extension::bytes-3, content::binary>> = content
    mime_type = :mimerl.extension(String.downcase(extension))
    <<picture_type::8, content::binary>> = content
    {description, image_data} = take_zero_terminated_text(content, format)

    # debug_write(image_data, mime_type)

    {:PIC,
     %{
       extension: extension,
       mime_type: mime_type,
       picture_type: picture_type,
       image_data: image_data,
       description: description
     }}
  end

  def parse_v220_frame(frame_id, content), do: {frame_id, content}

  @spec text_to_utf8(binary(), non_neg_integer()) :: String.t()
  def text_to_utf8(text, format)
  # Encoding 1 == utf16
  def text_to_utf8(<<0xFF, 0xFE, utf16_text::binary>>, 1),
    do: :unicode.characters_to_binary(utf16_text, {:utf16, :little})

  def text_to_utf8(<<0xFE, 0xFF, utf16_text::binary>>, 1),
    do: :unicode.characters_to_binary(utf16_text, {:utf16, :big})

  # This is not supposed to be done this way, but appears so lets be lenient
  def text_to_utf8("", 1), do: ""

  # Encoding 0 == ISO-8859-1
  def text_to_utf8(text, 0) do
    text
    |> :unicode.characters_to_binary(:latin1)
  end

  def parse_syncsafe_integer(
        <<0::1, size_1::unsigned-7, 0::1, size_2::unsigned-7, 0::size(1), size_3::size(7),
          0::size(1), size_4::size(7), rest::binary>>
      ) do
    value =
      [size_1, size_2, size_3, size_4]
      |> Enum.reduce(fn e, acc ->
        acc * 0b1000_0000 + e
      end)

    {:ok, value, rest}
  end

  def parse_syncsafe_integer(rest), do: {:error, binary_part(rest, 0, 4)}

  # Encoding 1 == utf8
  def parse_text_frame_content(<<text_format::8, content::binary>>) do
    content
    |> text_to_utf8(text_format)
    |> String.trim_trailing(<<0>>)
  end

  def take_zero_terminated(binary) when is_binary(binary) do
    case :binary.split(binary, <<0>>) do
      [a, b] -> {a, b}
      [b] -> {b, ""}
    end
  end

  @spec take_zero_terminated_text(binary(), non_neg_integer()) :: {String.t(), binary()}
  def take_zero_terminated_text(binary, format) do
    {a, b} = take_zero_terminated(binary)
    {text_to_utf8(a, format), b}
  end

  def take_text_format(<<text_format::8, rest::binary>>) do
    {text_format, rest}
  end

  # Internal debugging helpers
  def debug_write(bytes, mime_type) do
    extension =
      case :mimerl.mime_to_exts(mime_type) do
        [first_ext | _] -> first_ext
        _ -> "png"
      end

    name =
      "#{Time.utc_now()}"
      |> String.replace(":", "-")
      |> String.replace(".", "_")

    File.write!(Path.join(["/tmp", "Temp_#{name}.#{extension}"]), bytes)
  end
end
