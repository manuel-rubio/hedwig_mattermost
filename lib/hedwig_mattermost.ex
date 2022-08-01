defmodule HedwigMattermost do
  use Application

  def start(_type, _args) do
    children = [
      HedwigMattermost.Connection.Supervisor
    ]

    opts = [strategy: :one_for_one, name: HedwigMattermost.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
