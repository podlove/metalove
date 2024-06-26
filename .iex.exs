global_settings = "~/.iex.exs"
if File.exists?(global_settings), do: Code.require_file(global_settings)

Application.put_env(:elixir, :ansi_enabled, true)

# IEx.configure(
#   colors: [
#     eval_result: [:cyan, :bright],
#     eval_error: [[:red, :bright, "\n▶▶▶\n"]],
#     eval_info: [:yellow, :bright]
#   ],
#   default_prompt:
#     [
#       # cursor ⇒ column 1
#       "\e[G",
#       :white,
#       "%prefix",
#       :cyan,
#       "|",
#       :white,
#       "%counter",
#       " ",
#       :cyan,
#       "▶",
#       :reset
#     ]
#     |> IO.ANSI.format()
#     |> IO.chardata_to_string()
# )


alias Metalove.{Podcast, PodcastFeed, Episode, Enclosure, Fetcher, MediaParser}
