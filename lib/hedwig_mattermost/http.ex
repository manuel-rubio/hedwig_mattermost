defmodule HedwigMattermost.HTTP do
  require Logger

  def login(url, username, password) do
    url = url <> "/api/v3/users/login"
    body = Poison.encode!(%{
      "login_id": username,
      "password": password
    })
    case HTTPoison.post(url, body, headers()) do
      {:ok, %{status_code: 200} = resp} ->
        token = :proplists.get_value("Token", resp.headers)
        {:ok, token}
      error ->
        Logger.info("login error: #{inspect(error)}")
        format_error(error)
    end
  end

  def create_post(url, token, team_id, post) do
    url = url <> "/api/v3/teams/#{team_id}/channels/#{post.channel_id}/posts/create"
    body = Poison.encode!(post)
    case HTTPoison.post(url, body, headers(token)) do
      {:ok, %{status_code: 200}} -> :ok
      error ->
        Logger.info("create post error: #{inspect(error)}")
        format_error(error)
    end
  end

  def list_teams(url, token) do
    url = url <> "/api/v3/teams/all"
    case HTTPoison.get(url, headers(token)) do
      {:ok, %{status_code: 200} = resp} ->
        teams =
          Poison.decode!(resp.body)
          |> Enum.map(fn({id, _}) -> id end)
        {:ok, teams}
      error ->
        Logger.info("list teams error: #{inspect(error)}")
        format_error(error)
    end
  end

  def list_channels(url, token, team_id) when is_binary(team_id) do
    url = url <> "/api/v3/teams/#{team_id}/channels/"
    case HTTPoison.get(url, headers(token)) do
      {:ok, %{status_code: 200} = resp} ->
        channels =
          Poison.decode!(resp.body)
          |> Enum.map(fn(channel) -> channel["id"] end)
        {:ok, channels}
      error ->
        Logger.info("list channels error: #{inspect(error)}")
        format_error(error)
    end
  end

  def list_channels(url, token, team_ids) when is_list(team_ids) do
    make_team_channels = fn
      (team, accumulator) when is_map(accumulator) ->
        list_channels(url, token, team)
        |> maybe_put_team_channels(team, accumulator)
      (_, error) -> error
    end

    case Enum.reduce(team_ids, %{}, make_team_channels) do
      team_channels when is_map(team_channels) ->
        {:ok, make_channel_team(team_channels)}
      error -> error
    end
  end

  defp maybe_put_team_channels({:ok, _} = channels, team, acc), do: Map.put(acc, team, channels)
  defp maybe_put_team_channels(error, _, _), do: error

  defp make_channel_team(team_channel) do
    for team <- Map.keys(team_channel),
        {:ok, channels} = team_channel[team],
        channel <- channels,
        into: %{} do
      {channel, team}
    end
  end

  defp format_error({:error, _} = error), do: error
  defp format_error({:ok, %HTTPoison.Response{} = resp}), do: {:error, resp}

  defp headers(), do: %{"Content-type" => "application/json"}
  defp headers(token), do: %{"Content-type" => "application/json", "Authorization" => "Bearer #{token}"}
end
