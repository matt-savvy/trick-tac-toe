defmodule TrickTacToe.GameSupervisor do
  use DynamicSupervisor

  alias TrickTacToe.GameServer

  @agent_name {:global, TrickTacToe.GameSupervisor.IdAgent}

  def start_link(init_arg, name \\ __MODULE__) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: name)
  end

  @doc """
  Starts a new game under the given supervisor. Uses a global transaction
  so we can be assured the game id is unique across nodes.
  """
  def new_game(supervisor_name \\ __MODULE__) do
    case :global.whereis_name(@agent_name) do
      :undefined -> Agent.start_link(fn -> 1 end, name: @agent_name)
      _pid -> :noop
    end

    :global.trans({:new_game, self()}, fn -> do_new_game(supervisor_name) end)
  end

  defp do_new_game(supervisor_name \\ __MODULE__) do
    game_id = next_id()

    with {:ok, pid} <- DynamicSupervisor.start_child(supervisor_name, {GameServer, game_id}) do
      game = GameServer.get_state(pid)
      Agent.update(@agent_name, fn _ -> game_id + 1 end)

      {:ok, game, game_id}
    else
      {:error, {:already_started, _pid}} -> do_new_game()
    end
  end

  defp next_id do
    id = Agent.get(@agent_name, & &1)
    do_next_id(id)
  end

  defp do_next_id(id) do
    case GameServer.game_exists?(id) do
      false -> id
      true -> do_next_id(id + 1)
    end
  end

  # server
  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
