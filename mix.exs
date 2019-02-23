defmodule Metalove.MixProject do
  use Mix.Project

  def project do
    [
      app: :metalove,
      version: "0.1.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps()
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
      {:cachex, "~> 3.1"},
      {:jason, "~> 1.1"},
      # Needs to be this commit for correct supply of m4a
      {:mimerl, "~> 1.2", override: true}

      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"},
    ]
  end
end
