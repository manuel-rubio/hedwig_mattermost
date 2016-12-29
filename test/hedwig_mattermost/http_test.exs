defmodule HedwigMattermost.HTTPTest do
  use ExUnit.Case

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

  defp setup_endpoint(_) do
    server = Bypass.open()
    {:ok, server: server}
  end

end
