defmodule Metalove.MixProject do
  use Mix.Project

  @version "0.2.1"
  @url_github "https://github.com/podlove/metalove"

  def project do
    [
      app: :metalove,
      name: "Metalove",
      version: @version,
      description:
        "Scrape podcast RSS feeds and extract and provide as much of the metadata available as possible. Includes ID3.2.x parsing of mp3 podcast relevant metadata (chapter marks including URLs and images)",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps(),

      # Docs
      docs: [
        source_url: @url_github,
        source_ref: "v#{@version}",
        main: "readme",
        extras: ["README.md"]
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
      {:httpoison, "~> 1.5"},
      # html parsing
      {:floki, "~> 0.20"},
      # rss feed parsing
      {:sweet_xml, "~> 0.6"},
      {:timex, "~> 3.4"},
      {:jason, "~> 1.1"},
      {:mimerl, "~> 1.2"},
      {:xml_builder, "~> 2.0"},
      {:sizeable, "~>1.0"},
      # documentation
      {:ex_doc, "~> 0.19", optional: true, runtime: false, only: :dev}
    ]
  end

  defp package do
    [
      maintainers: ["Dominik Wagner"],
      licenses: ["MIT"],
      links: %{"GitHub" => @url_github},
      exclude_patterns: [".DS_Store"]
    ]
  end
end
