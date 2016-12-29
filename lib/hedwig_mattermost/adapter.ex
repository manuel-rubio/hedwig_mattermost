defmodule HedwigMattermost.Adapter do
  use Hedwig.Adapter

  require Logger

  alias HedwigMattermost.{HTTP, Connection}

  defmodule State do
    defstruct robot: nil,
      url: nil,
      username: nil,
      password: nil,
      user_id: nil,
      conn_pid: nil,
      conn_ref: nil
  end

  def init({robot, opts}) do
    {username, opts} = Keyword.pop(opts, :username)
    {password, opts} = Keyword.pop(opts, :password)
    {url, _opts} = Keyword.pop(opts, :mattermost_url)
    Kernel.send(self(), :start)
    state = %State{
      robot: robot,
      username: username,
      password: password,
      url: url,
    }
    {:ok, state}
  end

  def handle_in(pid, msg) do
    # handle messages from websocket here
    GenServer.cast(pid, {:in, msg})
  end

  def handle_cast({:in, %{"event" => "hello"} = msg}, state) do
    user_id = msg["broadcast"]["user_id"]
    Hedwig.Robot.handle_connect(state.robot)
    {:noreply, %State{state | user_id: user_id}}
  end

  def handle_cast({:in, msg}, state) do
    Logger.debug("unhandled message from connection: #{inspect(msg)}")
    {:noreply, state}
  end

  def handle_info(:start, %{url: url, username: username, password: password} = state) do
    case HTTP.login(url, username, password) do
      {:ok, token} ->
        {:ok, pid} = Supervisor.start_child(Connection.Supervisor, [self(), url, token])
        ref = Process.monitor(pid)
        {:noreply, %State{state | conn_pid: pid, conn_ref: ref}}
      error ->
        handle_network_failure(error, state)
    end
  end

  def handle_info({:DOWN, ref, :process, pid, reason}, %{conn_pid: pid, conn_ref: ref} = state) do
    handle_network_failure(reason, state)
  end

  defp handle_network_failure(reason, %{robot: robot} = state) do
    case Hedwig.Robot.handle_disconnect(robot, reason) do
      {:disconnect, reason} ->
        {:stop, reason, state}
      {:reconnect, timeout} ->
        Process.send_after(self(), :start, timeout)
        {:noreply, reset_state(state)}
      :reconnect ->
        Kernel.send(self(), :start)
        {:noreply, reset_state(state)}
    end
  end

  defp reset_state(state) do
    %State{state | conn_pid: nil, conn_ref: nil}
  end
end
