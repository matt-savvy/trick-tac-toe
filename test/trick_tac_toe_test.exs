defmodule TrickTacToeTest do
  use ExUnit.Case
  doctest TrickTacToe

  test "greets the world" do
    assert TrickTacToe.hello() == :world
  end
end
