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

  ## server
  @impl true
  def init(_) do
    {:ok, Game.new()}
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end
end
