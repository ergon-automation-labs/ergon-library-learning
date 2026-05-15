import Config

if config_env() != :test do
  database_url =
    System.get_env("DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      For example: postgresql://user:password@localhost:5432/bot_army_learning
      """

  config :bot_army_learning, BotArmyLearning.Repo,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
    ssl: String.to_existing_atom(System.get_env("ECTO_NO_SSL") || "false")
end
