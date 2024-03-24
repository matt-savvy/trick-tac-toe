defmodule TrickTacToe.Board do
  @moduledoc """
  Board is represented as
  a1 a2 a3
  b1 b2 b3
  c1 c2 c3
  """

  defstruct [
    :a1,
    :a2,
    :a3,
    :b1,
    :b2,
    :b3,
    :c1,
    :c2,
    :c3
  ]

  @winning_combos [
    [:a1, :a2, :a3],
    [:b1, :b2, :b3],
    [:c1, :c2, :c3],
    [:a1, :b1, :c1],
    [:a2, :b2, :c2],
    [:a3, :b3, :c3],
    [:a1, :b2, :c3],
    [:a3, :b2, :c1]
  ]

  def result(%__MODULE__{} = board) do
    board_map = board |> Map.from_struct()

    winner = Enum.find_value(@winning_combos, &winning_combo(board_map, &1))

    case winner do
      {:just, p} -> {:winner, p}
      _ -> incomplete_or_tie(board_map)
    end
  end

  defp winning_combo(board_map, positions) do
    case Enum.map(positions, &Map.get(board_map, &1)) do
      [p, p, p] when not is_nil(p) -> {:just, p}
      _ -> nil
    end
  end

  defp incomplete_or_tie(board_map) do
    board_map
    |> Map.values()
    |> Enum.member?(nil)
    |> case do
      true -> :incomplete
      false -> :tie
    end
  end
end
