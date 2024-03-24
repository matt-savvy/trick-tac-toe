defmodule TrickTacToe.GameServer do
  use GenServer

  alias TrickTacToe.Game

  ## client
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, nil)
  end

  def get_state(pid) do
    GenServer.call(pid, :get_state)
  end

  def join(pid, player) do
    GenServer.call(pid, {:join, player})
  end

  ## server
  @impl true
  def init(_) do
    {:ok, Game.new()}
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_call({:join, player}, _from, state) do
    with {:ok, game} <- Game.join(state, player) do
      {:reply, {:ok, game}, game}
    else
      {:error, :player_taken} ->
        {:reply, {:error, state}, state}
    end
  end
end
