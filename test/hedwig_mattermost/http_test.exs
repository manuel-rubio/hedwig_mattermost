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
        |> Plug.Conn.put_resp_header("Token", "1234")
        |> Plug.Conn.resp(200, "")
      end)

      {:ok, "1234"} = HTTP.login(mattermost_url, username, password)
    end

    test "when 401 returns token_undefined error", %{server: server} do
      username = "abc"
      password = "1234"
      mattermost_url = "http://localhost:#{server.port}"

      Bypass.expect(server, fn(conn) ->
        Plug.Conn.resp(conn, 401, "")
      end)

      {:error, :token_undefined} = HTTP.login(mattermost_url, username, password)
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
