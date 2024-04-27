defmodule TrickTacToe.GameServerTest do
  use ExUnit.Case, async: true

  alias TrickTacToe.{Game, GameServer}

  test "integration test" do
    refute GameServer.game_exists?(0)

    id = 2
    new_game = Game.new(id)
    assert {:ok, pid} = GameServer.start_link(id)
    assert is_pid(pid)
    assert GameServer.game_exists?(id)

    assert {:ok, new_game} == GameServer.get_state(id)

    {:ok, _game} = GameServer.join(id, :x)
    {:ok, game} = GameServer.join(id, :o)
    {:error, ^game} = GameServer.join(id, :x)

    assert {:ok,
            %Game{
              players: %{x: true, o: true}
            }} = GameServer.get_state(id)

    {:ok, _game} = GameServer.make_move(id, {:x, :a1})
    # invalid move, wrong player
    {:error, :wrong_player} = GameServer.make_move(id, {:x, :a2})
    # invalid move, position taken
    {:error, :position_taken} = GameServer.make_move(id, {:o, :a1})
    {:ok, _game} = GameServer.make_move(id, {:o, :b3})
    {:ok, _game} = GameServer.make_move(id, {:x, :a2})
    {:ok, _game} = GameServer.make_move(id, {:o, :b1})
    {:ok, _game} = GameServer.make_move(id, {:x, :c2})
    {:ok, _game} = GameServer.make_move(id, {:o, :c3})
    {:ok, _game} = GameServer.make_move(id, {:x, :b2})
    {:error, :game_over} = GameServer.make_move(id, {:o, :a3})

    assert {:ok,
            %Game{
              status: {:winner, :x}
            }} = GameServer.get_state(id)

    assert {:error, :not_found} = GameServer.get_state(-100)

    assert next_id = GameServer.play_again(id)
    assert {:ok, _game} = GameServer.get_state(next_id)
    assert ^next_id = GameServer.play_again(id)
  end
end
