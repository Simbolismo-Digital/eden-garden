defmodule EdenGarden.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    topologies = [
      eden_garden: [
        strategy: Cluster.Strategy.Gossip
      ]
    ]

    children = [
      # Start the Telemetry supervisor
      EdenGardenWeb.Telemetry,
      # Start the Ecto repository
      # EdenGarden.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: EdenGarden.PubSub},
      # Start Finch
      {Finch, name: EdenGarden.Finch},
      # Start the Endpoint (http/https)
      {Cluster.Supervisor, [topologies, [name: EdenGarden.ClusterSupervisor]]},
      EdenGardenWeb.Endpoint,
      {Horde.Registry, [name: EdenGarden.HordeRegistry, keys: :unique]},
      {Horde.DynamicSupervisor, [name: EdenGarden.HordeSupervisor, strategy: :one_for_one, process_redistribution: :active]},
      EdenGarden.NodeListener
      # Start a worker by calling: EdenGarden.Worker.start_link(arg)
      # {EdenGarden.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: EdenGarden.Supervisor]
    link = Supervisor.start_link(children, opts)
    horde_start_links()
    link
  end

  defp horde_start_links() do
    # Macieira
    Horde.DynamicSupervisor.start_child(EdenGarden.HordeSupervisor,
      %{
        id: "EdenGarden.TreeServer.Macieira",
        type: :worker,
        restart: :transient,
        start: {EdenGarden.TreeServer, :start_link, ["maçã"]}
      })
    # Laranjeira
    Horde.DynamicSupervisor.start_child(EdenGarden.HordeSupervisor,
      %{
        id: "EdenGarden.TreeServer.Laranjeira",
        type: :worker,
        restart: :transient,
        start: {EdenGarden.TreeServer, :start_link, ["laranja"]}
      })
    # Bananeira
    Horde.DynamicSupervisor.start_child(EdenGarden.HordeSupervisor,
      %{
        id: "EdenGarden.TreeServer.Bananeira",
        type: :worker,
        restart: :transient,
        start: {EdenGarden.TreeServer, :start_link, ["banana"]}
      })
    # # Basket main
    # Horde.DynamicSupervisor.start_child(EdenGarden.HordeSupervisor, Horde.DynamicSupervisor.child_spec({EdenGarden.BasketServer, "main"}))
    # # Basket backup
    # Horde.DynamicSupervisor.start_child(EdenGarden.HordeSupervisor, Horde.DynamicSupervisor.child_spec({EdenGarden.BasketServer, "backup"}))
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    EdenGardenWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
