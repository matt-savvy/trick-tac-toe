defmodule TrickTacToe.GameServer do
  use GenServer

  alias TrickTacToe.Game

  ## client
  def start_link(id) do
    GenServer.start_link(__MODULE__, id, name: name(id))
  end

  def get_state(pid) when is_pid(pid) do
    GenServer.call(pid, :get_state)
  end

  def get_state(id) do
    id
    |> name
    |> GenServer.call(:get_state)
  end

  def join(id, player) do
    id
    |> name
    |> GenServer.call({:join, player})
  end

  def make_move(id, {_player, _position} = move) do
    id
    |> name
    |> GenServer.call({:make_move, move})
  end

  def name(id) do
    {:via, Registry, {TrickTacToe.Registry, id}}
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

  @impl true
  def handle_call({:make_move, move}, _from, state) do
    new_state = Game.make_move(state, move)
    {:reply, new_state, new_state}
  end
end
