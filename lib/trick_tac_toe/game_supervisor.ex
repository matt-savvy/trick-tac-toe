defmodule TrickTacToe.GameSupervisor do
  use DynamicSupervisor

  alias TrickTacToe.GameServer

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  def new_game do
    game_id = next_id()

    with {:ok, pid} <- DynamicSupervisor.start_child(__MODULE__, {GameServer, game_id}) do
      game = GameServer.get_state(pid)
      {:ok, game, game_id}
    end
  end

  defp next_id do
    System.unique_integer([:monotonic, :positive])
  end

  # server
  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
