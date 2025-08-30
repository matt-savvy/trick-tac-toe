defmodule TrickTacToeWeb.GameLive do
  use TrickTacToeWeb, :live_view

  alias TrickTacToe.{Board, Game, GameServer, GameSupervisor}
  alias TrickTacToeWeb.Endpoint

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(params, url, socket) do
    {:noreply,
     socket
     |> assign_new(:url, fn -> url end)
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :new, _params) do
    with {:ok, _game, game_id} <- GameSupervisor.new_game() do
      socket |> navigate_to_game(game_id)
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
  def handle_event("copy-link", _, socket) do
    {:noreply, socket |> push_event("copyLink", %{url: socket.assigns.url})}
  end

  @impl true
  def handle_event("play-again", _, socket) do
    next_game_id = socket.assigns.game_id |> GameServer.play_again()

    {:noreply,
     socket
     |> navigate_to_game(next_game_id)
     |> put_flash(:info, "A new game has started!")}
  end

  @impl true
  def handle_info({:update, game}, socket) do
    {:noreply, socket |> assign_game(game)}
  end

  @impl true
  def handle_info({:next_game, next_game_id}, socket) do
    {:noreply,
     socket
     |> navigate_to_game(next_game_id)
     |> put_flash(:info, "A new game has started!")}
  end

  @impl true
  def handle_info({:DOWN, _ref, :process, _pid, {:shutdown, :timeout}}, socket) do
    {:noreply, socket |> put_flash(:error, "The game has been closed due to inactivity.")}
  end

  defp navigate_to_game(socket, game_id) do
    socket
    |> push_navigate(to: ~p"/#{game_id}")
  end

  defp move_allowed?(_square_player = nil, %Game{status: :incomplete} = game, player) do
    Game.get_turn(game) == player
  end

  defp move_allowed?(_square_player, _game, _player), do: false

  defp show_board?(%Game{players: %{x: true}}, :x), do: true

  defp show_board?(%Game{players: players}, _player) do
    players.x and players.o
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div id="game" phx-hook="LocalStateStore">
      <div :for={player <- Game.available_players(@game)} :if={is_nil(@player)}>
        <.link phx-click="join" phx-value-player={player}>
          Join game as {player}.
        </.link>
      </div>

      <div :if={not is_nil(@player)}>
        You have joined the game as {@player}.
        <div :for={player <- Game.available_players(@game)}>
          Waiting for {player} to join.
          Send them this link to join the game:
          <.link
            phx-click="copy-link"
            title="Click to copy link"
            class="text-sm font-semibold leading-6 text-zinc-900 hover:text-zinc-700"
          >
            <.icon name="hero-clipboard" /> Click here to copy game link.
          </.link>
        </div>
      </div>

      <div :if={show_board?(@game, @player)} class="sm:w-full md:w-5/6 mx-auto">
        <h1 :if={@game.status == :incomplete}>It is player {Game.get_turn(@game)}'s turn.</h1>
        <h1 :if={@game.status != :incomplete}>
          {status_string(@game.status)}.
          <.link phx-click="play-again" class="text-indigo-900 hover:text-indigo-600 font-semibold">
            Click here to play again!
          </.link>
        </h1>
        <div class="grid grid-cols-3 grid-rows-3 gap-0 justify-items-center">
          <div
            :for={{position, player} <- positions(@board)}
            class={[
              "border-solid border-2 border-slate-500 w-full aspect-square flex items-center justify-center",
              move_allowed?(player, @game, @player) && "hover:bg-sky-100 hover:cursor-pointer"
            ]}
            phx-click={move_allowed?(player, @game, @player) && "move"}
            phx-value-position={position}
          >
            <.player>
              {player}
            </.player>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp player(assigns) do
    ~H"""
    <span class="font-sans text-5xl lg:text-7xl">
      {render_slot(@inner_block)}
    </span>
    """
  end

  defp status_string({:winner, :x}), do: "X Wins"
  defp status_string({:winner, :o}), do: "O Wins"
  defp status_string(:incomplete), do: nil

  defp positions(%Board{} = board) do
    for {k, v} <- Map.from_struct(board) do
      {Atom.to_string(k), v}
    end
    |> Enum.sort_by(fn {k, _v} -> k end, :asc)
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
