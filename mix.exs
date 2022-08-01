defmodule HedwigMattermost.Mixfile do
  use Mix.Project

  def project do
    [
      app: :hedwig_mattermost,
      version: "0.1.0",
      elixir: "~> 1.3",
      elixirc_paths: elixirc_paths(Mix.env()),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "Mattermost adapter for the Hedwig bot framework.",
      package: package()
    ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [
      extra_applications: [:logger],
      mod: {HedwigMattermost, []}
    ]
  end

  defp deps do
    [
      {:hedwig, github: "manuel-rubio/hedwig", branch: "master"},
      {:poison, "~> 5.0"},
      {:websocket_client, "~> 1.4"},
      {:httpoison, "~> 1.8"},

      # Test dependencies
      {:plug, "~> 1.4.3", only: :test},
      {:bypass, "~> 0.8.1", only: :test},
      {:credo, "~> 1.6", only: [:dev, :test]}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp package do
    [
      files: ["lib", "mix.exs", "README.md"],
      maintainers: ["Troels Brødsgaard"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/trarbr/hedwig_mattermost"
      }
    ]
  end
end
