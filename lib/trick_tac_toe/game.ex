defmodule TrickTacToe.Game do
  defstruct status: :incomplete,
            moves: []

  alias TrickTacToe.Board

  @doc """
  Creates a new game.
  """
  def new do
    %__MODULE__{}
  end

  @doc """
  Creates a Board from the moves.
  """
  def get_board(%__MODULE__{moves: moves}) do
    Enum.reduce(moves, %Board{}, fn {player, position}, board ->
      %{board | position => player}
    end)
  end
end
