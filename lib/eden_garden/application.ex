defmodule EdenGarden.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
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
      EdenGardenWeb.Endpoint
      # Start a worker by calling: EdenGarden.Worker.start_link(arg)
      # {EdenGarden.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: EdenGarden.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    EdenGardenWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
