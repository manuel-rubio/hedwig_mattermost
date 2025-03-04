defmodule HedwigMattermost.Connection do
  @moduledoc false

  require Logger

  alias HedwigMattermost.Adapter

  @behaviour :websocket_client
  @keepalive 30_000

  def start_link(owner_pid, url, token) do
    ws_url = String.replace(url, "http", "ws") <> "/api/v4/websocket"
    :websocket_client.start_link(to_charlist(ws_url), __MODULE__, [owner_pid, token])
  end

  # :websocket_client callbacks
  def init([owner_pid, token]) do
    Logger.debug("websocket init")
    owner_ref = Process.monitor(owner_pid)

    state = %{
      owner_pid: owner_pid,
      owner_ref: owner_ref,
      token: token,
      seq: 1
    }

    {:reconnect, state}
  end

  def onconnect(_req, state) do
    Logger.debug("websocket onconnect")
    send(self(), {:send_token, state.token})
    {:ok, state, @keepalive}
  end

  def ondisconnect(reason, state) do
    Logger.debug("websocket ondisconnect")
    {:close, reason, state}
  end

  def websocket_handle({:text, data}, _req, %{owner_pid: owner} = state) do
    msg = Poison.decode!(data)
    Adapter.handle_in(owner, msg)
    {:ok, state}
  end

  def websocket_handle({:ping, data}, _req, state) do
    Logger.debug("websocket ping")
    {:reply, {:pong, data}, state}
  end

  def websocket_handle({:pong, _data}, _req, state) do
    Logger.debug("websocket pong")
    {:ok, state}
  end

  def websocket_handle(msg, _req, state) do
    Logger.warn(fn -> "Received unhandled websocket message: #{inspect(msg)}" end)
    {:ok, state}
  end

  def websocket_info({:send_token, token}, _req, state) do
    Logger.debug("websocket send_token")

    msg = %{
      seq: state.seq,
      action: "authentication_challenge",
      data: %{
        token: token
      }
    }

    data = Poison.encode!(msg)
    next_state = %{state | seq: state.seq + 1}
    {:reply, {:text, data}, next_state}
  end

  def websocket_info(
        {:DOWN, ref, :process, pid, _reason},
        _req,
        %{owner_pid: pid, owner_ref: ref} = state
      ) do
    {:close, "", state}
  end

  def websocket_info(msg, _req, state) do
    Logger.warn(fn -> "Received unhandled message: #{inspect(msg)}" end)
    {:ok, state}
  end

  def websocket_terminate(_reason, _req, _state) do
    :ok
  end
end
