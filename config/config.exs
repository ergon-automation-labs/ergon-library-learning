import Config

config :bot_army_learning, ecto_repos: [BotArmyLearning.Repo]

config :logger, :console,
  format: "[$level] $message\n",
  metadata: [:request_id]
