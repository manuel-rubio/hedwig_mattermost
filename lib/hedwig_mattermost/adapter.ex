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
      token: nil
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
    text = "@#{msg.user.name} " <> msg.text
    do_post(text, msg, state)
  end

  def handle_cast({:send, msg}, state) do
    do_post(msg.text, msg, state)
  end

  def handle_cast({:emote, msg}, state) do
    text = "*" <> msg.text <> "*"
    do_post(text, msg, state)
  end

  def handle_info(:start, %{url: url, username: username, password: password} = state) do
    with {:ok, token} <- HTTP.login(url, username, password),
         {:ok, pid} <- Supervisor.start_child(Connection.Supervisor, [self(), url, token]) do
      ref = Process.monitor(pid)
      next_state = %State{state |
        conn_pid: pid,
        conn_ref: ref,
        token: token,
      }
      {:noreply, next_state}
    else
      error -> handle_network_failure(error, state)
    end
  end

  def handle_info({:DOWN, ref, :process, pid, reason}, %{conn_pid: pid, conn_ref: ref} = state) do
    handle_network_failure(reason, state)
  end

  defp do_post(text, msg, state) do
    post =
      msg
      |> to_post(state.user_id)
      |> add_text(text)
      |> add_attachments(msg.private)

    HTTP.create_post(state.url, state.token, post)

    {:noreply, state}
  end

  defp to_post(msg, user_id) do
    %{
      user_id: user_id,
      channel_id: msg.room,
      message: nil,
      props: %{},
    }
  end

  defp add_text(post, nil), do: post
  defp add_text(post, ""), do: post
  defp add_text(post, text), do: %{post | message: text}

  defp add_attachments(post, %{attachments: attachments}) do
    put_in(post, [:props, :attachments], attachments)
  end

  defp add_attachments(post, _msg), do: post

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
    %State{state |
      user_id: nil,
      conn_pid: nil,
      conn_ref: nil,
      token: nil,
    }
  end
end
