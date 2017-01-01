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
      conn_ref: nil,
      token: nil,
      teams: [],
      channel_team: %{}
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

  def handle_cast({:in, %{"event" => "user_added"} = msg}, %{user_id: user_id} = state) do
    # update channel_team if the event is for the bot user
    channel_team = case msg["data"]["user_id"] do
      ^user_id ->
        channel_id = msg["broadcast"]["channel_id"]
        team_id = msg["data"]["team_id"]
        Map.put(state.channel_team, channel_id, team_id)
      _ -> state.channel_team
    end
    {:noreply, %{state | channel_team: channel_team}}
  end

  def handle_cast({:in, %{"event" => "direct_added"} = msg}, %{user_id: user_id} = state) do
    # the direct_added event does not carry team_id
    # so the entire channel_team map is built again
    channel_team = case msg["data"]["teammate_id"] do
      ^user_id ->
        {:ok, channel_team} = HTTP.list_channels(state.url, state.token, state.teams)
        channel_team
      _ -> state.channel_team
    end
    {:noreply, %{state | channel_team: channel_team}}
  end

  def handle_cast({:in, %{"event" => "posted"} = msg}, %{robot: robot} = state) do
    post = Poison.decode!(msg["data"]["post"])
    msg = %Hedwig.Message{
      ref: make_ref(),
      robot: robot,
      room: post["channel_id"],
      text: post["message"],
      user: %Hedwig.User{
        id: post["user_id"],
        name: msg["data"]["sender_name"]
      }
    }

    # Ignore empty messages and messages from the bot
    if msg.text && msg.user.id != state.user_id do
      :ok = Hedwig.Robot.handle_in(robot, msg)
    end

    {:noreply, state}
  end

  def handle_cast({:in, msg}, state) do
    Logger.debug("unhandled message from connection: #{inspect(msg)}")
    {:noreply, state}
  end

  def handle_cast({:reply, msg}, state) do
    team_id = state.channel_team[msg.room]
    text = "@#{msg.user.name} " <> format_text(msg.text)
    HTTP.create_post(state.url, state.token, team_id, msg.room, state.user_id, text)
    {:noreply, state}
  end

  def handle_cast({:send, msg}, state) do
    team_id = state.channel_team[msg.room]
    text = format_text(msg.text)
    HTTP.create_post(state.url, state.token, team_id, msg.room, state.user_id, text)
    {:noreply, state}
  end

  def handle_cast({:emote, msg}, state) do
    team_id = state.channel_team[msg.room]
    text = "*" <> format_text(msg.text) <> "*"
    HTTP.create_post(state.url, state.token, team_id, msg.room, state.user_id, text)
    {:noreply, state}
  end

  def handle_info(:start, %{url: url, username: username, password: password} = state) do
    with {:ok, token} <- HTTP.login(url, username, password),
         {:ok, teams} <- HTTP.list_teams(url, token),
         {:ok, channel_team} <- HTTP.list_channels(url, token, teams),
         {:ok, pid} <- Supervisor.start_child(Connection.Supervisor, [self(), url, token]) do
      ref = Process.monitor(pid)
      next_state = %State{state |
        conn_pid: pid,
        conn_ref: ref,
        token: token,
        teams: teams,
        channel_team: channel_team
      }
      {:noreply, next_state}
    else
      error -> handle_network_failure(error, state)
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

  defp format_text(text) do
    String.replace(text, "\n", "\\n")
  end

  defp reset_state(state) do
    %State{state |
      user_id: nil,
      conn_pid: nil,
      conn_ref: nil,
      token: nil,
      teams: [],
      channel_team: %{}
    }
  end
end
