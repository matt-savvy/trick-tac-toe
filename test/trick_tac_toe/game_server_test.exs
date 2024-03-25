defmodule TrickTacToe.GameServerTest do
  use ExUnit.Case, async: true

  alias TrickTacToe.{Game, GameServer}

  test "integration test" do
    new_game = Game.new()
    id = 2
    assert {:ok, pid} = GameServer.start_link(id)
    assert is_pid(pid)

    assert new_game == GameServer.get_state(id)

    {:ok, _game} = GameServer.join(id, :x)
    {:ok, game} = GameServer.join(id, :o)
    {:error, ^game} = GameServer.join(id, :x)

    assert %Game{
             players: %{x: true, o: true}
           } = GameServer.get_state(id)

    GameServer.make_move(id, {:x, :a1})
    GameServer.make_move(id, {:o, :b3})
    GameServer.make_move(id, {:x, :a2})
    GameServer.make_move(id, {:o, :b1})
    GameServer.make_move(id, {:x, :c2})
    GameServer.make_move(id, {:o, :c3})
    GameServer.make_move(id, {:x, :b2})

    assert %Game{
             status: {:winner, :x}
           } = GameServer.get_state(id)
  end
end
