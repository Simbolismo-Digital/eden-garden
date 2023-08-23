defmodule EdenGarden.TreeServer do
  use GenServer

  def start_link(fruit) do
    GenServer.start_link(__MODULE__, [fruit], name: __MODULE__)
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
    IO.puts("Criamos uma árvore de #{fruit}s")
    Process.send_after(self(), :periodic_task, random_interval())
    {:ok, %{fruit: fruit, load: []}}
  end

  def handle_call(:pop, _from, %{load: load} = state) do
    case load do
      [] ->
        IO.puts("Sem frutas...")
        {:reply, nil, []}

      [fruit | rest] ->
        IO.puts("Fruta removida: #{fruit}")
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
    IO.puts("Nasceu uma nova '#{fruit}': #{inspect(new_load)}")
    %{state | load: new_load}
  end

  defp random_interval do
    :timer.seconds(Enum.random(2..5))
  end
end
