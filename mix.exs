defmodule Metalove.MixProject do
  use Mix.Project

  @version "0.4.0"
  @url_github "https://github.com/podlove/metalove"

  def project do
    [
      app: :metalove,
      name: "Metalove",
      version: @version,
      description:
        "Scrape podcast RSS feeds and extract and provide as much of the metadata available as possible. Includes ID3.2.x parsing of mp3 podcast relevant metadata (chapter marks including URLs and images)",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),

      # Docs
      docs: [
        source_url: @url_github,
        source_ref: "v#{@version}",
        main: "Metalove",
        extras: ["CHANGELOG.md"]
      ],
      package: package()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Metalove.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:req, "~> 0.5.15"},
      {:plug, "~> 1.16", only: :test},
      {:nimble_options, "~> 1.1"},
      # html parsing
      {:floki, "~> 0.38"},
      # rss feed parsing
      {:sweet_xml, "~> 0.6.6"},
      {:timex, "~> 3.7"},
      {:jason, "~> 1.4"},
      {:mimerl, "~> 1.4"},
      {:xml_builder, "~> 2.4"},
      {:sizeable, "~>1.0"},
      {:chapters, "~>1.0.1"},
      # documentation
      {:ex_doc, "~> 0.31", optional: true, runtime: false, only: :dev}
    ]
  end

  defp package do
    [
      maintainers: ["Dominik Wagner", "Eric Teubert"],
      licenses: ["MIT"],
      links: %{"GitHub" => @url_github},
      exclude_patterns: [".DS_Store"]
    ]
  end
end
