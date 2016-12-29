defmodule HedwigMattermost.Support.WebSocketServer do
  @behaviour :cowboy_websocket_handler
  @listen_ip {127, 0, 0, 1}

  def open(handler) do
    ref = make_ref()
    port = get_available_port()
    start_socket(handler, port, ref)
  end

  defp get_available_port do
    {:ok, socket} = :ranch_tcp.listen(ip: @listen_ip, port: 0)
    {:ok, port} = :inet.port(socket)
    true = :erlang.port_close(socket)
    port
  end

  defp start_socket(handler, port, ref) do
    {:ok, socket} = :ranch_tcp.listen(ip: @listen_ip, port: port)
    dispatch = [{:_, [{:_, handler, []}]}]
    cowboy_opts = [ref: ref, acceptors: 3, port: port, socket: socket, dispatch: dispatch]
    {:ok, pid} = Plug.Adapters.Cowboy.http(__MODULE__, [], cowboy_opts)
    %{pid: pid, port: port}
  end

  ## WebSocket Callbacks

  require Logger

  def init(_, req, opts) do
    {:upgrade, :protocol, :cowboy_websocket, req, opts}
  end

  def websocket_init(_, req, opts) do
    {:ok, req, opts, 5000}
  end

  def websocket_handle({:ping, msg}, req, state) do
    {:reply, {:pong, msg}, req, state}
  end

  def websocket_handle({:text, data}, req, state) do
    %{"seq" => seq, "action" => "authentication_challenge"} = Poison.decode!(data)
    reply = ~s({"status":"OK","seq_reply":#{seq}})
    {:reply, {:text, reply}, req, state}
  end

  def websocket_terminate(_reason, _req, _state) do
    :ok
  end
end
