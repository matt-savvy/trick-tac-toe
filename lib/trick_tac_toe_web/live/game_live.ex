defmodule TrickTacToeWeb.GameLive do
  use TrickTacToeWeb, :live_view

  alias TrickTacToe.{Board, Game, GameServer, GameSupervisor}

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :new, _params) do
    with {:ok, _game, game_id} <- GameSupervisor.new_game(),
         {:ok, _game} <- GameServer.join(game_id, :x),
         {:ok, _game} <- GameServer.join(game_id, :o) do
      socket |> push_redirect(to: ~p"/#{game_id}")
    end
  end

  defp apply_action(socket, :existing, %{"id" => id}) do
    id = String.to_integer(id)

    {:ok, game} = GameServer.get_state(id)
    socket |> assign(:game_id, id) |> assign_game(game)
  end

  defp assign_game(socket, game) do
    socket
    |> assign(:game, game)
    |> assign(:board, Game.get_board(game))
    |> assign(:player, Game.get_turn(game))
  end

  @impl true
  def handle_event("move", %{"position" => position}, socket) do
    position = String.to_atom(position)
    move = {socket.assigns.player, position}
    game = GameServer.make_move(socket.assigns.game_id, move)

    {:noreply, socket |> assign_game(game)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <h1 :if={@game.status == :incomplete}>It is player <%= @player %>'s turn.</h1>
    <h1 :if={@game.status != :incomplete}><%= status_string(@game.status) %></h1>
    <div class="grid grid-cols-3 grid-rows-3 gap-12">
      <div
        :for={{position, player} <- positions(@board)}
        class="border-solid border-2 border-sky-500 h-40 min-w-1"
      >
        <.link
          :if={is_nil(player) and @game.status == :incomplete}
          phx-click="move"
          phx-value-position={position}
        >
          move here
        </.link>
        <%= player %>
      </div>
    </div>
    """
  end

  defp status_string({:winner, :x}), do: "X Wins"
  defp status_string({:winner, :o}), do: "O Wins"
  defp status_string(:incomplete), do: nil

  defp positions(%Board{} = board) do
    board
    |> Map.from_struct()
    |> Map.to_list()
  end
end
