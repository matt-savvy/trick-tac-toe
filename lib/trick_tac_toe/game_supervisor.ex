defmodule TrickTacToe.GameSupervisor do
  use DynamicSupervisor

  alias TrickTacToe.GameServer

  @agent_name {:global, TrickTacToe.GameSupervisor.IdAgent}

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  def new_game do
    case :global.whereis_name(@agent_name) do
      :undefined -> Agent.start_link(fn -> 0 end, name: @agent_name)
      _pid -> :noop
    end

    :global.trans(
      {:new_game, self()},
      fn ->
        game_id = next_id()

        with {:ok, pid} <- DynamicSupervisor.start_child(__MODULE__, {GameServer, game_id}) do
          game = GameServer.get_state(pid)
          Agent.update(@agent_name, fn _ -> game_id end)

          {:ok, game, game_id}
        end
      end
    )
  end

  defp next_id do
    id = Agent.get(@agent_name, & &1)
    do_next_id(id)
  end

  defp do_next_id(id) do
    case GameServer.get_state(id) do
      {:error, :not_found} -> id
      {:ok, _state} -> do_next_id(id + 1)
    end
  end

  def list_games do
    DynamicSupervisor.which_children(__MODULE__)
    |> Enum.map(fn
      {:undefined, pid, :worker, [GameServer]} ->
        {pid}
    end)
  end

  # server
  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
