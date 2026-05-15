defmodule BotArmyLearning.Application do
  @moduledoc """
  BotArmyLearning shared library application.

  Provides learning primitives consumed by the Bot Army ecosystem:
  - OutcomeTracker: records outcomes and computes accuracy
  - ThresholdAdapter: adjusts thresholds based on historical performance
  - PromptOptimizer: improves prompts from feedback signals

  This is a library application — it does not have a persistent runtime
  presence. Consumers start the relevant GenServers in their own
  supervision trees.
  """

  use Application

  @impl true
  def start(_type, _args) do
    # Start Repo so consumers can use OutcomeTracker + PromptOptimizer with persistence.
    # Consumers still start individual learning GenServers in their own supervision trees.
    children = [
      BotArmyLearning.Repo
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: BotArmyLearning.Supervisor)
  end
end
