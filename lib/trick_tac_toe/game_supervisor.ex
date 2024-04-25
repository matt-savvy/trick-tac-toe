defmodule TrickTacToe.GameSupervisor do
  use DynamicSupervisor

  alias TrickTacToe.GameServer

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  def new_game do
    :global.trans(
      {:new_game, self()},
      fn ->
        game_id = next_id()

        with {:ok, pid} <- DynamicSupervisor.start_child(__MODULE__, {GameServer, game_id}) do
          game = GameServer.get_state(pid)
          {:ok, game, game_id}
        end
      end
    )
  end

  defp next_id do
    do_next_id(0)
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
