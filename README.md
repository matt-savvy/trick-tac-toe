# TrickTacToe

To start your Phoenix server:

  * Run `mix setup` to install and setup dependencies
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

## To test clustering locally

In one terminal tab:
```
PORT=4000 iex --name a@127.0.0.1 --cookie asdf -S mix phx.server
```

In another terminal tab:
```
PORT=4001 iex --name b@127.0.0.1 --cookie asdf -S mix phx.server
```

Then, connect the nodes.
```elixir
iex(b@127.0.0.1)1> Node.connect(:"a@127.0.0.1")
true
iex(b@127.0.0.1)2> Node.list
[:"a@127.0.0.1"]
```
