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

  describe "get_state/1" do
    test "returns state" do
      new_game = Game.new()

      pid = start_supervised!(GameServer)

      assert new_game == GameServer.get_state(pid)
    end
  end
end
