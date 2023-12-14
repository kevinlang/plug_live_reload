defmodule PlugLiveReload.MixProject do
  use Mix.Project

  @source_url "https://github.com/kevinlang/plug_live_reload"
  @version "0.2.0"

  def project do
    [
      app: :plug_live_reload,
      version: @version,
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps(),

      # Hex
      description: "Adds live-reload functionality to Plug for development.",
      package: package(),

      # Docs
      source_url: @source_url,
      homepage_url: @source_url,
      docs: docs()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {PlugLiveReload.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:file_system, "~> 1.0"},
      {:plug, "~> 1.15"},
      {:cowboy, "~> 2.10"},
      {:ex_doc, "~> 0.31", only: :docs, runtime: false}
      # {:jason, "~> 1.2"}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end

  defp package do
    [
      maintainers: ["Kevin Lang"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url
      }
    ]
  end

  defp docs do
    [
      source_ref: "v#{@version}",
      source_url: @source_url,
      extras: [
        "README.md"
      ],
      main: "readme"
    ]
  end
end
