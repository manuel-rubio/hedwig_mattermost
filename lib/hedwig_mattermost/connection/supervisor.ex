defmodule HedwigMattermost.Connection.Supervisor do
  @moduledoc false
  use DynamicSupervisor

  def start_link([]) do
    DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl DynamicSupervisor
  def init([]) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_child(args) do
    DynamicSupervisor.start_child(__MODULE__, {HedwigMattermost.Connection, args})
  end
end
