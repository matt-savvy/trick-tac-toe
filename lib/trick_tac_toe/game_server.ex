defmodule TrickTacToe.GameServer do
  use GenServer, restart: :transient

  alias TrickTacToe.{Game, GameSupervisor}

  alias Phoenix.PubSub

  @timeout 60 * 60 * 1000

  ## client

  @doc """
  Starts a GameServer process linked to the current process.
  """
  def start_link(id) do
    GenServer.start_link(__MODULE__, id, name: name(id))
  end

  @doc """
  Returns true if a GameServer process exists for this id
  """
  def game_exists?(id) do
    case :global.whereis_name(global_id(id)) do
      :undefined -> false
      pid when is_pid(pid) -> true
    end
  end

  @doc """
  Returns the state of the GameServer for the given pid or id.
  """
  def get_state(pid) when is_pid(pid) do
    GenServer.call(pid, :get_state)
  end

  def get_state(id) do
    case :global.whereis_name(global_id(id)) do
      :undefined -> {:error, :not_found}
      pid when is_pid(pid) -> {:ok, GenServer.call(pid, :get_state)}
    end
  end

  @doc """
  Joins game as player and updates GameServer state.
  """
  def join(id, player) do
    id
    |> name
    |> GenServer.call({:join, player})
  end

  @doc """
  Makes a move and updates GameServer state.
  """
  def make_move(id, {_player, _position} = move) do
    id
    |> name
    |> GenServer.call({:make_move, move})
  end

  @doc """
  Start a new game, if applicable. Returns the next game's id.
  """
  def play_again(id) do
    id
    |> name
    |> GenServer.call(:play_again)
  end

  @doc """
  Gets the GameServer name from an id. Can be used to send
  messages to the GameServer.
  """
  def name(id) do
    {:global, global_id(id)}
  end

  defp global_id(id) do
    {:game, id}
  end

  @doc """
  Broadcasts an :update message on the topic for the game, with
  the current state.
  """
  def broadcast_update!(%Game{next_game: next_id} = game) when not is_nil(next_id) do
    PubSub.broadcast!(TrickTacToe.PubSub, topic(game), {:next_game, next_id})
  end

  def broadcast_update!(%Game{} = game) do
    PubSub.broadcast!(TrickTacToe.PubSub, topic(game), {:update, game})
  end

  @doc """
  Subscribes the caller process to the topic for the game.
  """
  def subscribe(%Game{} = game) do
    :ok = PubSub.subscribe(TrickTacToe.PubSub, topic(game))
  end

  defp topic(%Game{id: id}) do
    "game:#{id}"
  end

  ## server
  @impl true
  def init(id) do
    {:ok, Game.new(id)}
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    reply_success(state, state)
  end

  @impl true
  def handle_call({:join, player}, _from, state) do
    with {:ok, game} <- Game.join(state, player) do
      broadcast_update!(game)
      reply_success({:ok, game}, game)
    else
      {:error, :player_taken} ->
        reply_success({:error, state}, state)
    end
  end

  @impl true
  def handle_call({:make_move, move}, _from, state) do
    with {:ok, new_state} <- Game.make_move(state, move) do
      broadcast_update!(new_state)
      reply_success({:ok, new_state}, new_state)
    else
      {:error, error} ->
        reply_success({:error, error}, state)
    end
  end

  @impl true
  def handle_call(:play_again, _from, %{next_game: nil} = state) do
    {:ok, _game, next_id} = GameSupervisor.new_game()
    next_state = %{state | next_game: next_id}
    broadcast_update!(next_state)

    {:reply, next_id, next_state}
  end

  @impl true
  def handle_call(:play_again, _from, %{next_game: next_id} = state) do
    {:reply, next_id, state}
  end

  @impl true
  def handle_info(:timeout, state) do
    {:stop, {:shutdown, :timeout}, state}
  end

  defp reply_success(reply, state) do
    {:reply, reply, state, timeout()}
  end

  defp timeout do
    Application.get_env(TrickTacToe, :timeout, @timeout)
  end
end
