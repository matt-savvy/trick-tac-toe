defmodule TrickTacToe.GameServerTest do
  use ExUnit.Case, async: true

  alias TrickTacToe.{Game, GameServer}

  test "integration test" do
    new_game = Game.new()

    assert {:ok, pid} = GameServer.start_link(nil)
    assert new_game == GameServer.get_state(pid)

    {:ok, _game} = GameServer.join(pid, :x)
    {:ok, game} = GameServer.join(pid, :o)
    {:error, ^game} = GameServer.join(pid, :x)

    assert %Game{
             players: %{x: true, o: true}
           } = GameServer.get_state(pid)

    GameServer.make_move(pid, {:x, :a1})
    GameServer.make_move(pid, {:o, :b3})
    GameServer.make_move(pid, {:x, :a2})
    GameServer.make_move(pid, {:o, :b1})
    GameServer.make_move(pid, {:x, :c2})
    GameServer.make_move(pid, {:o, :c3})
    GameServer.make_move(pid, {:x, :b2})

    assert %Game{
             status: {:winner, :x}
           } = GameServer.get_state(pid)
  end
end
