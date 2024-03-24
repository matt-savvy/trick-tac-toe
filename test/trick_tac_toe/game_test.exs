defmodule TrickTacToe.GameTest do
  use ExUnit.Case, async: true

  alias TrickTacToe.Game

  describe "new/0" do
    test "creates a new game" do
      assert %Game{
               moves: [],
               status: :incomplete
             } = Game.new()
    end
  end
end
