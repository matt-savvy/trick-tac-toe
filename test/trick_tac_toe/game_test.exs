defmodule TrickTacToe.GameTest do
  use ExUnit.Case, async: true

  alias TrickTacToe.{Board, Game}

  describe "new/0" do
    test "creates a new game" do
      assert %Game{
               moves: [],
               status: :incomplete
             } = Game.new()
    end
  end

  describe "get_board/1" do
    test "reduces moves" do
      game = %Game{
        moves: [
          {:x, :a1},
          {:o, :b1},
          {:x, :c3},
          {:o, :a2}
        ]
      }

      assert %Board{
               a1: :x,
               a2: :o,
               b1: :o,
               c3: :x
             } == Game.get_board(game)
    end
  end
end
