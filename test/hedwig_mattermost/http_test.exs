defmodule HedwigMattermost.HTTPTest do
  use ExUnit.Case, async: true

  alias HedwigMattermost.HTTP

  describe "login" do
    setup :setup_endpoint

    test "returns token", %{server: server} do
      username = "abc"
      password = "1234"
      mattermost_url = "http://localhost:#{server.port}"

      Bypass.expect(server, fn(conn) ->
        assert conn.method == "POST"
        assert conn.request_path == "/api/v3/users/login"
        conn
        |> Plug.Conn.put_resp_header("Token", "XKCD")
        |> Plug.Conn.resp(200, "")
      end)

      {:ok, "XKCD"} = HTTP.login(mattermost_url, username, password)
    end

    test "when status code is not 200, returns error", %{server: server} do
      username = "abc"
      password = "1234"
      mattermost_url = "http://localhost:#{server.port}"

      Bypass.expect(server, fn(conn) ->
        Plug.Conn.resp(conn, 401, "")
      end)

      {:error, _} = HTTP.login(mattermost_url, username, password)
    end

    test "bad url returns HTTPoison error" do
      username = "abc"
      password = "1234"
      mattermost_url = "http://foreignhost"

      {:error, %HTTPoison.Error{reason: :nxdomain}} = HTTP.login(mattermost_url, username, password)
    end
  end

  describe "list teams" do
    setup :setup_endpoint

    test "returns a list of strings", %{server: server} do
      token = "XKCD"
      mattermost_url = "http://localhost:#{server.port}"
      [t1, t2] = expected_teams = ["team1", "team2"]

      Bypass.expect(server, fn(conn) ->
        auth = :proplists.get_value("authorization", conn.req_headers)
        assert auth == "Bearer #{token}"
        assert conn.method == "GET"
        assert conn.request_path == "/api/v3/teams/all"
        body = ~s({"#{t1}":{"id":"#{t1}"}, "#{t2}":{"id":"#{t2}"}})
        Plug.Conn.resp(conn, 200, body)
      end)

      {:ok, actual_teams} = HTTP.list_teams(mattermost_url, token)
      Enum.each(expected_teams, fn(team) ->
        assert team in actual_teams
      end)
    end
  end

  describe "list channels" do
    setup :setup_endpoint

    test "returns a list of strings", %{server: server} do
      token = "XKCD"
      mattermost_url = "http://localhost:#{server.port}"
      team_id = "team1"
      [c1, c2] = expected_channels = ["channel1", "channel2"]

      Bypass.expect(server, fn(conn) ->
        auth = :proplists.get_value("authorization", conn.req_headers)
        assert auth == "Bearer #{token}"
        assert conn.method == "GET"
        assert conn.request_path == "/api/v3/teams/#{team_id}/channels/"
        body = ~s([{"id":"#{c1}"}, {"id":"#{c2}"}])
        Plug.Conn.resp(conn, 200, body)
      end)

      {:ok, actual_channels} = HTTP.list_channels(mattermost_url, token, team_id)
      Enum.each(expected_channels, fn(channel) ->
        assert channel in actual_channels
      end)
    end

    test  "works for a list of teams", %{server: server} do
      token = "XKCD"
      mattermost_url = "http://localhost:#{server.port}"
      [t1, t2] = team_ids = ["team1", "team2"]
      [c1, c2, c3] = expected_channels = ["channel1", "channel2", "channel3"]

      Bypass.expect(server, fn(conn) ->
        auth = :proplists.get_value("authorization", conn.req_headers)
        assert auth == "Bearer #{token}"
        assert conn.method == "GET"
        body = if String.contains?(conn.request_path, t1) do
          ~s([{"id":"#{c1}"}, {"id":"#{c2}"}])
        else
          ~s([{"id":"#{c3}"}])
        end
        Plug.Conn.resp(conn, 200, body)
      end)

      {:ok, actual_channels} = HTTP.list_channels(mattermost_url, token, team_ids)
      Enum.each(expected_channels, fn(channel) ->
        assert channel in Map.keys(actual_channels)
      end)
      assert actual_channels[c1] == t1
      assert actual_channels[c3] == t2
    end
  end

  defp setup_endpoint(_) do
    server = Bypass.open()
    {:ok, server: server}
  end

end
