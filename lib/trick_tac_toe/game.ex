defmodule TrickTacToe.Game do
  defstruct status: :incomplete,
            moves: []

  @doc """
  Creates a new game.
  """
  def new do
    %__MODULE__{}
  end
end
