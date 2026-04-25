defmodule BotArmyLearning.Application do
  @moduledoc """
  BotArmyLearning application supervisor.

  Manages Learning bot services:
  - NATS message consumer
  - Session manager for active learning sessions
  - Card storage (in-memory + Ecto persistence)
  """

  use Application

  @env Mix.env()

  @impl true
  def start(_type, _args) do
    children =
      []
      |> maybe_add_repo()
      |> maybe_add_card_store()
      |> maybe_add_session_manager()
      |> maybe_add_pulse_publisher()
      |> maybe_add_consumer()

    opts = [strategy: :one_for_one, name: BotArmyLearning.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp maybe_add_repo(children) do
    if @env == :test, do: children, else: [BotArmyLearning.Repo | children]
  end

  defp maybe_add_card_store(children) do
    if @env == :test, do: children, else: [{BotArmyLearning.CardStore, []} | children]
  end

  defp maybe_add_session_manager(children) do
    if @env == :test, do: children, else: [{BotArmyLearning.SessionManager, []} | children]
  end

  defp maybe_add_pulse_publisher(children) do
    if @env == :test, do: children, else: [{BotArmyLearning.PulsePublisher, []} | children]
  end

  defp maybe_add_consumer(children) do
    if @env == :test, do: children, else: [{BotArmyLearning.NATS.Consumer, []} | children]
  end
end
