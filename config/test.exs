import Config

# Test configuration uses isolated test database
# Does NOT use runtime.exs environment variable overrides (compile-time only)
config :bot_army_learning, BotArmyLearning.Repo,
  database: System.get_env("BOT_ARMY_LEARNING_TEST_DB_NAME", "ergon_learning_test"),
  hostname: System.get_env("BOT_ARMY_LEARNING_DB_HOST", "localhost"),
  port: String.to_integer(System.get_env("BOT_ARMY_LEARNING_DB_PORT", "30003")),
  username: System.get_env("BOT_ARMY_LEARNING_DB_USER", "postgres"),
  password: System.get_env("BOT_ARMY_LEARNING_DB_PASSWORD", "postgres"),
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 1

# Use mock card store in tests (no real data access)
config :bot_army_learning, card_store: BotArmyLearning.CardStoreMock
