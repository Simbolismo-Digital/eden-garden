defmodule EdenGarden.TreeServer do
  use GenServer

  @names %{
    "maçã" => "#{__MODULE__}.Macieira",
    "laranja" => "#{__MODULE__}.Laranjeira",
    "banana" => "#{__MODULE__}.Bananeira"
  }

  # seconds
  @period Enum.random(2..5)

  def start_link(fruit) do
    GenServer.start_link(__MODULE__, [fruit], name: {:global, @names[fruit]})
  end

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
    :timer.seconds(@period)
  end
end
