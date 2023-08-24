defmodule EdenGarden.BasketServer do
  use GenServer

  @names %{
    "main" => "#{__MODULE__}.Main",
    "backup" => "#{__MODULE__}.Backup"
  }

  # seconds
  @period 1

  def start_link(role) do
    GenServer.start_link(__MODULE__, [role], name: {:global, @names[role]})
  end

  # Api

  def is_online(name) do
    :global.registered_names()
    |> Enum.filter(&is_bitstring/1)
    |> Enum.filter(&String.contains?(&1, name))
    |> length()
    |> Kernel.>=(1)
  end

  def transfer(pid, transered, role) do
    IO.puts("[Basket: #{role}] Transferindo #{length(transered)} frutas para #{inspect(pid)}")
    GenServer.call(pid, {:transfer, transered})
  end

  def list(pid) do
    GenServer.call(pid, :list)
  end

  # Callbacks

  def init([role]) do
    IO.puts("[Basket: #{role}] Criamos uma cesta #{role}")
    Process.flag(:trap_exit, true)
    Process.send_after(self(), :periodic_task, random_interval())
    {:ok, %{role: role, load: []}}
  end

  def handle_call(:list, _from, state) do
    {:reply, state, state}
  end

  def handle_call({:transfer, transfered}, _from, %{load: load, role: role} = state) do
    new_load = load ++ transfered
    IO.puts("[Basket: #{role}] Nova carga: #{length(new_load)} frutas")
    {:reply, :ok, %{state | load: new_load}}
  end

  def handle_info({:EXIT, _from, :shutdown}, %{load: load, role: "main"} = state) do
    IO.puts("[Basket: main] Encerrando a cesta")
    transfer(:global.whereis_name("Elixir.EdenGarden.BasketServer.Backup"), load, "main")
    Process.flag(:trap_exit, false)
    Process.exit(self(), :normal)
    {:noreply, state}
  end

  def handle_info({:EXIT, _from, :shutdown}, %{role: "backup"} = state) do
    IO.puts("[Basket: backup] Encerrando a cesta")
    Process.flag(:trap_exit, false)
    Process.exit(self(), :normal)
    {:noreply, state}
  end

  def handle_info(:periodic_task, state) do
    Process.send_after(self(), :periodic_task, random_interval())
    new_state = handle_periodic_task(state)
    {:noreply, new_state}
  end

  defp handle_periodic_task(%{role: "main", load: load} = state) do
    fruit = pick_a_fruit("main")

    if fruit do
      new_load = [fruit | load]
      IO.puts("[Basket: main] Coletamos uma '#{fruit}'. Carga atual #{length(new_load)} frutas")
      %{state | load: new_load}
    else
      IO.puts("[Basket: main] Não coletamos nada dessa vez. Carga atual #{length(load)} frutas")
      state
    end
  end

  defp handle_periodic_task(%{load: load, role: "backup"} = state) do
    case load do
      [] ->
        IO.puts("[Basket: backup] Backup fica na reserva...")
        state

      load ->
        IO.puts("[Basket: backup] Transferindo de volta para o principal...")

        if is_online("BasketServer.Main") do
          transfer(:global.whereis_name("Elixir.EdenGarden.BasketServer.Main"), load, "backup")
          %{state | load: []}
        else
          state
        end
    end
  end

  defp random_interval do
    :timer.seconds(@period)
  end

  defp pick_a_fruit(role) do
    Enum.random(online_trees())
    |> tap(&IO.puts("[Basket: #{role}] Coletando da #{&1}"))
    |> :global.whereis_name()
    |> EdenGarden.TreeServer.pop()
  end

  defp online_trees do
    :global.registered_names()
    |> Enum.filter(&is_bitstring/1)
    |> Enum.filter(&String.contains?(&1, "EdenGarden.TreeServer"))
  end
end
