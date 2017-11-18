[![Build Status](https://travis-ci.org/trarbr/hedwig_mattermost.svg?branch=master)](https://travis-ci.org/trarbr/hedwig_mattermost)

# HedwigMattermost

Mattermost adapter for the Hedwig bot framework.

## Installation

HedwigMattermost can be installed from [Hex](https://hex.pm/packages/hedwig_mattermost):

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

In addition to the standard Hedwig configuration parameter,s HedwigMattermost requires the following configuration to be present: `mattermost_url`, `username` and `password`. `username` and `password` must match a user account for your Mattermost instance. `username` can be either an email or username, depending on the settings for email authentication in Mattermost. Example:

```elixir
config :alfred, Alfred.Robot,
  adapter: HedwigMattermost.Adapter,
  name: "alfred",
  aka: "/",
  username: "alfred@example.org",
  password: "super_secret",
  mattermost_url: "https://mattermost.example.org",
  responders: [
    {Hedwig.Responders.Help, []},
    {Hedwig.Responders.Ping, []}
  ]
```
