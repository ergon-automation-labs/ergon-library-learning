defmodule BotArmyLearning.Release do
  @moduledoc """
  Release tasks for database migrations.

  Migrations are run via the shared BotArmyRuntime.Ecto.MigrationRunner:

      eval 'BotArmyLearning.Release.migrate()'

  Called from Salt during bot deployment, before the bot starts.
  """

  def migrate do
    BotArmyRuntime.Ecto.MigrationRunner.run(
      repo_module: BotArmyLearning.Repo,
      app_module: :bot_army_library_learning
    )
  end
end
