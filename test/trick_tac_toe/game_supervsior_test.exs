defmodule TrickTacToe.GameSupervisorTest do
  use ExUnit.Case, async: true

  alias TrickTacToe.{Game, GameServer, GameSupervisor}

  test "integration test" do
    assert {:ok, %Game{}, game_1_id} = GameSupervisor.new_game()
    assert {:ok, %Game{}, game_2_id} = GameSupervisor.new_game()
    assert {:ok, %Game{}, game_3_id} = GameSupervisor.new_game()

    {:ok, game_1} = GameServer.join(game_1_id, :x)
    {:ok, game_2} = GameServer.join(game_2_id, :o)
    {:ok, _game_3} = GameServer.join(game_3_id, :x)
    {:ok, game_3} = GameServer.join(game_3_id, :o)

    assert {:ok, ^game_1} = GameServer.get_state(game_1_id)
    assert {:ok, ^game_2} = GameServer.get_state(game_2_id)
    assert {:ok, ^game_3} = GameServer.get_state(game_3_id)

    assert [
             {:undefined, game_1_pid, :worker, [GameServer]},
             {:undefined, game_2_pid, :worker, [GameServer]},
             {:undefined, game_3_pid, :worker, [GameServer]}
           ] = DynamicSupervisor.which_children(GameSupervisor)

    assert :ok = GenServer.stop(game_1_pid, :normal)
    refute Process.alive?(game_1_pid)
    assert Process.alive?(game_2_pid)
    assert Process.alive?(game_3_pid)
    Process.sleep(50)
    assert {:ok, %Game{}} = GameServer.get_state(game_1_id)
  end
end
