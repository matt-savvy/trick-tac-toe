defmodule TrickTacToe.GameServerTest do
  use ExUnit.Case, async: true

  alias TrickTacToe.{Game, GameServer}

  describe "start_link/1" do
    test "starts with new game" do
      new_game = Game.new()

      {:ok, pid} = GameServer.start_link(nil)

      assert new_game == :sys.get_state(pid)
    end
  end
end
