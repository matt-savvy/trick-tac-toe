defmodule TrickTacToe.GameServer do
  use GenServer

  alias TrickTacToe.Game

  ## client
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, nil)
  end

  ## server
  @impl true
  def init(_) do
    {:ok, Game.new()}
  end
end
