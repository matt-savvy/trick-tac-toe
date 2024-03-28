import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :trick_tac_toe, TrickTacToeWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "3XSgwd5usFjlULz85OvNu2W83I79rTx81NKiDRjuLl9S0MoTCWaC7Hpk3J7iHMh7",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
