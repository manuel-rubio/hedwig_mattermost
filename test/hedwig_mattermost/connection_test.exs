defmodule HedwigMattermost.ConnectionTest do
  use ExUnit.Case

  require Logger

  alias HedwigMattermost.{Connection, Support.WebSocketServer}

  setup do
    server = WebSocketServer.open(WebSocketServer)
    {:ok, server: server}
  end

  test "websocket authentication", %{server: server} do
    url = "http://localhost:#{server.port}"
    token = 1234
    {:ok, _pid} = Connection.start_link(self(), url, token)

    assert_receive({:"$gen_cast", {:in, %{"seq_reply" => 1, "status" => "OK"}}})
  end
end
