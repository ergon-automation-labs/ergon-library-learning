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
    # Library application — no long-lived processes at the top level.
    # Consumers start individual learning GenServers as needed.
    children = []
    Supervisor.start_link(children, strategy: :one_for_one, name: BotArmyLearning.Supervisor)
  end
end
