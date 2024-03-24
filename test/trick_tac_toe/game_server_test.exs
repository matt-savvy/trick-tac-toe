defmodule TrickTacToe.GameServerTest do
  use ExUnit.Case, async: true

  alias TrickTacToe.{Game, GameServer}

  test "integration test" do
    new_game = Game.new()

    assert {:ok, pid} = GameServer.start_link(nil)
    assert new_game == GameServer.get_state(pid)
  end
end
