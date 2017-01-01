defmodule HedwigMattermost.Mixfile do
  use Mix.Project

  def project do
    [app: :hedwig_mattermost,
     version: "0.1.0",
     elixir: "~> 1.3",
     elixirc_paths: elixirc_paths(Mix.env),
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [
      applications: [
        :logger,
        :hedwig,
        :websocket_client,
        :httpoison,
      ],
      mod: {HedwigMattermost, []}
    ]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:hedwig, "~> 1.0"},
      {:poison, "~> 3.0"},
      {:websocket_client, "~> 1.2"},
      {:httpoison, "~> 0.10"},

      # Test dependencies
      {:plug, "~> 1.0", only: :test},
      {:bypass, "~> 0.5", only: :test},
      {:credo, "~> 0.5", only: [:dev, :test]},
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
