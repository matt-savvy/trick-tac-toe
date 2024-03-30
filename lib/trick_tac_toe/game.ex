defmodule TrickTacToe.Game do
  defstruct [
    :id,
    status: :incomplete,
    moves: [],
    players: %{x: false, o: false}
  ]

  alias TrickTacToe.Board

  @doc """
  Creates a new game.
  """
  def new(id) do
    %__MODULE__{id: id}
  end

  @doc """
  """
  def join(%__MODULE__{players: players} = game, player) do
    case Map.get(players, player) do
      false -> {:ok, %{game | players: Map.put(players, player, true)}}
      true -> {:error, :player_taken}
    end
  end

  @doc """
  Lists available players.
  """
  def available_players(%__MODULE__{players: players}) do
    players
    |> Map.reject(fn {_k, v} -> v end)
    |> Map.keys()
  end

  @doc """
  Creates a Board from the moves.
  """
  def get_board(%__MODULE__{moves: moves}) do
    Enum.reduce(moves, %Board{}, fn {player, position}, board ->
      %{board | position => player}
    end)
  end

  @doc """
  Returns the player whose turn it is.
  """
  def get_turn(%__MODULE__{moves: []}), do: :x

  def get_turn(%__MODULE__{moves: [move | _rest]}) do
    {player, _position} = move

    case player do
      :x -> :o
      :o -> :x
    end
  end

  @doc """
  Makes a move.
  """
  def make_move(%__MODULE__{moves: moves} = game, {_player, _position} = move) do
    updated_game = %{game | moves: [move | moves]}

    updated_game
    |> get_board()
    |> Board.result()
    |> case do
      :incomplete -> drop_move(updated_game)
      result -> %{updated_game | status: result}
    end
  end

  defp drop_move(%__MODULE__{moves: moves} = game) do
    %{game | moves: Enum.take(moves, 4)}
  end
end
