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
    with {:ok, _game, game_id} <- GameSupervisor.new_game() do
      socket |> push_redirect(to: ~p"/#{game_id}")
    end
  end

  defp apply_action(socket, :existing, %{"id" => id}) do
    id = String.to_integer(id)

    case GameServer.get_state(id) do
      {:ok, game} ->
        :ok = GameServer.subscribe(game)

        socket
        |> assign(:game_id, id)
        |> assign(:player, nil)
        |> assign_game(game)

      {:error, :not_found} ->
        raise TrickTacToeWeb.NotFound
    end
  end

  defp assign_game(socket, game) do
    socket
    |> assign(:game, game)
    |> assign(:board, Game.get_board(game))
  end

  @impl true
  def handle_event("join", %{"player" => player}, socket) do
    player = String.to_existing_atom(player)
    game_id = socket.assigns.game_id

    case GameServer.join(game_id, player) do
      {:ok, game} ->
        {:noreply, socket |> assign_game(game) |> assign(:player, player)}

      {:error, :player_taken} ->
        game = GameServer.get_state(game_id)
        {:noreply, socket |> assign_game(game) |> put_flash(:error, "That player was taken")}
    end
  end

  @impl true
  def handle_event("move", %{"position" => position}, socket) do
    position = String.to_atom(position)
    move = {socket.assigns.player, position}
    game = GameServer.make_move(socket.assigns.game_id, move)

    {:noreply, socket |> assign_game(game)}
  end

  @impl true
  def handle_info({:update, game}, socket) do
    {:noreply, socket |> assign_game(game)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div :for={player <- Game.available_players(@game)}>
      <.link phx-click="join" phx-value-player={player}>
        Join game as <%= player %>.
      </.link>
    </div>

    <h1 :if={not is_nil(@player)}>You have joined the game as <%= @player %></h1>

    <div :if={Game.available_players(@game) == []}>
      <h1 :if={@game.status == :incomplete}>It is player <%= Game.get_turn(@game) %>'s turn.</h1>
      <h1 :if={@game.status != :incomplete}><%= status_string(@game.status) %></h1>
      <div class="grid grid-cols-3 grid-rows-3 gap-12">
        <div
          :for={{position, player} <- positions(@board)}
          class="border-solid border-2 border-sky-500 h-40 min-w-1"
        >
          <.link
            :if={is_nil(player) and @game.status == :incomplete and Game.get_turn(@game) == @player}
            phx-click="move"
            phx-value-position={position}
          >
            move here
          </.link>
          <%= player %>
        </div>
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