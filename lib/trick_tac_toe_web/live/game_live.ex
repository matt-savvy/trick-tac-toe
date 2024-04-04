defmodule TrickTacToeWeb.GameLive do
  use TrickTacToeWeb, :live_view

  alias TrickTacToe.{Board, Game, GameServer, GameSupervisor}
  alias TrickTacToeWeb.Endpoint

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

        _ref =
          id
          |> GameServer.name()
          |> GenServer.whereis()
          |> Process.monitor()

        socket
        |> assign(:game_id, id)
        |> assign(:player, nil)
        |> assign_game(game)
        |> push_event("restore", %{key: id})

      {:error, :not_found} ->
        raise TrickTacToeWeb.NotFound
    end
  end

  defp assign_game(socket, game) do
    socket
    |> assign(:game, game)
    |> assign(:board, Game.get_board(game))
  end

  defp assign_error(socket, error) do
    case GameServer.get_state(socket.assigns.game_id) do
      {:ok, game} -> socket |> assign_game(game) |> put_flash(:error, error_string(error))
      {:error, :not_found} -> socket
    end
  end

  @impl true
  def handle_event("join", %{"player" => player}, %{assigns: %{player: nil}} = socket) do
    player = String.to_existing_atom(player)
    game_id = socket.assigns.game_id

    case GameServer.join(game_id, player) do
      {:ok, game} ->
        {:noreply,
         socket
         |> assign_game(game)
         |> assign(:player, player)
         |> push_event("store", %{key: game_id, data: serialize_to_token(player)})}

      {:error, _error} ->
        {:noreply, socket |> assign_error(:player_taken)}
    end
  end

  @impl true
  def handle_event("join", _params, socket) do
    {:noreply, socket |> assign_error(:player_selected)}
  end

  @impl true
  def handle_event("move", %{"position" => position}, socket) do
    position = String.to_atom(position)
    move = {socket.assigns.player, position}

    with {:ok, game} <- GameServer.make_move(socket.assigns.game_id, move) do
      {:noreply, socket |> assign_game(game)}
    else
      {:error, error} ->
        {:noreply, socket |> assign_error(error)}
    end
  end

  @impl true
  def handle_event("restore-player", token, socket) when is_binary(token) do
    case restore_from_token(token) do
      {:ok, player} ->
        {:noreply, socket |> assign(:player, player)}

      _ ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:update, game}, socket) do
    {:noreply, socket |> assign_game(game)}
  end

  @impl true
  def handle_info({:DOWN, _ref, :process, _pid, {:shutdown, :timeout}}, socket) do
    {:noreply, socket |> put_flash(:error, "The game has been closed due to inactivity.")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div id="game" phx-hook="LocalStateStore">
      <div :for={player <- Game.available_players(@game)} :if={is_nil(@player)}>
        <.link phx-click="join" phx-value-player={player}>
          Join game as <%= player %>.
        </.link>
      </div>

      <h1 :if={not is_nil(@player)}>You have joined the game as <%= @player %></h1>

      <div :if={Game.available_players(@game) == []}>
        <h1 :if={@game.status == :incomplete}>It is player <%= Game.get_turn(@game) %>'s turn.</h1>
        <h1 :if={@game.status != :incomplete}><%= status_string(@game.status) %></h1>
        <div class="grid grid-cols-3 grid-rows-3 gap-2 justify-items-center">
          <div
            :for={{position, player} <- positions(@board)}
            class="border-solid border-2 border-sky-500 h-24 w-24 md:h-32 md:w-32 lg:h-48 lg:w-48 flex items-center justify-center"
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

  defp error_string(:player_taken), do: "That player is already taken!"
  defp error_string(:player_selected), do: "You have already selected a player!"
  defp error_string(:wrong_player), do: "It's not your turn!"
  defp error_string(:position_taken), do: "That position is taken!"
  defp error_string(:game_over), do: "The game is over!"

  defp serialize_to_token(data) do
    Phoenix.Token.encrypt(Endpoint, salt(), data)
  end

  defp restore_from_token(token) do
    case Phoenix.Token.decrypt(Endpoint, salt(), token) do
      {:ok, data} ->
        {:ok, data}

      {:error, reason} ->
        {:error, "Failed to restore previous state. Reason: #{inspect(reason)}."}
    end
  end

  defp salt do
    Application.get_env(:trick_tac_toe, Endpoint)[:live_view][:signing_salt]
  end
end
