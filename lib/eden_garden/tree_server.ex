defmodule EdenGarden.TreeServer do
  use GenServer

  @names %{
    "maçã" => "EdenGarden.TreeServer.Macieira",
    "laranja" => "EdenGarden.TreeServer.Laranjeira",
    "banana" => "EdenGarden.TreeServer.Bananeira"
  }

  @spec start_link(any) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(fruit) do
    GenServer.start_link(__MODULE__, [fruit], name: via_tuple(@names[fruit]))
  end

  # Horde

  def via_tuple(name), do: {:via, Horde.Registry, {EdenGarden.HordeRegistry, name}}

  # Api

  def pop(pid) do
    GenServer.call(pid, :pop)
  end

  def list(pid) do
    GenServer.call(pid, :list)
  end

  # Callbacks

  def init([fruit]) do
    IO.puts("[Tree: #{fruit}] Criamos uma árvore de #{fruit}s")
    # Process.flag(:trap_exit, true)
    Process.send_after(self(), :periodic_task, random_interval())
    {:ok, %{fruit: fruit, load: []}}
  end

  def handle_call(:pop, _from, %{fruit: fruit, load: load} = state) do
    case load do
      [] ->
        IO.puts("[Tree: #{fruit}] Sem frutas...")
        {:reply, nil, state}

      [fruit | rest] ->
        IO.puts("[Tree: #{fruit}] Fruta coletada: #{fruit}")
        {:reply, fruit, %{state | load: rest}}
    end
  end

  def handle_call(:list, _from, state) do
    {:reply, state, state}
  end

  # def handle_info({:EXIT, _from, {:name_conflict, _, _, _}}, %{fruit: fruit} = state) do
  #   IO.puts("[Tree: #{fruit}]: processo iniciado em outro nodo, por favor se retire")
  #   {:stop, :normal, state}
  # end

  def handle_info(:periodic_task, state) do
    Process.send_after(self(), :periodic_task, random_interval())
    new_state = handle_periodic_task(state)
    {:noreply, new_state}
  end

  defp handle_periodic_task(%{fruit: fruit, load: load} = state) do
    new_load = [fruit | load]
    IO.puts("[Tree: #{fruit}] Nasceu uma nova '#{fruit}': #{inspect(new_load)}")
    %{state | load: new_load}
  end

  defp random_interval do
    :timer.seconds(Enum.random(2..5))
  end
end
