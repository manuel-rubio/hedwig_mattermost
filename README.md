[![Build Status](https://travis-ci.org/trarbr/hedwig_mattermost.svg?branch=master)](https://travis-ci.org/trarbr/hedwig_mattermost)

# HedwigMattermost

Mattermost adapter for the Hedwig bot framework.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add `hedwig_mattermost` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:hedwig_mattermost, "~> 0.1.0"}]
    end
    ```

  2. Ensure `hedwig_mattermost` is started before your application:

    ```elixir
    def application do
      [applications: [:hedwig_mattermost]]
    end
    ```

## Configuration

HedwigMattermost requires the following configuration to be present: `mattermost_url`, `username` and `password`. E.g.:

```elixir
config :alfred, Alfred.Robot,
  adapter: HedwigMattermost.Adapter,
  name: "alfred",
  aka: "/",
  username: "alfred",
  password: "super_secret",
  mattermost_url: "https://mattermost.example.org",
  responders: [
    {Hedwig.Responders.Help, []},
    {Hedwig.Responders.Ping, []}
  ]
```
