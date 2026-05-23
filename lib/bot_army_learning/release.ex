defmodule BotArmyLearning.Release do
  @moduledoc """
  Release tasks for database migrations.
  """

  def migrate do
    load_app()

    for repo <- repos() do
      {:ok, _fun_return, _apps} =
        Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end
  end

  defp repos do
    Application.fetch_env!(:bot_army_library_learning, :ecto_repos)
  end

  defp load_app do
    Application.load(:bot_army_library_learning)
  end
end
