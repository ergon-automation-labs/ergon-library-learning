defmodule BotArmyLearning.OutcomeTracker do
  @moduledoc """
  Generic outcome tracker for recording bot decisions and their results.

  Tracks whether a bot's decision (e.g. approve, reject, act, defer)
  was correct in hindsight, and computes per-category accuracy.

  ## Usage

      BotArmyLearning.OutcomeTracker.record(
        "proposal-1", "factory", "approved", "pass"
      )

      BotArmyLearning.OutcomeTracker.stats("factory")
      # => %{total: 10, correct: 8, accuracy: 0.8}
  """

  use GenServer
  require Logger

  @name __MODULE__

  # ── Client API ──────────────────────────────────────────────

  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name, @name)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @doc """
  Record an outcome.

  - `id` — identifier for the item being tracked
  - `category` — namespace for grouping (e.g. "factory", "intent")
  - `decision` — the decision that was made (e.g. "approved")
  - `actual_result` — what actually happened (e.g. "pass", "fail")
  """
  def record(id, category, decision, actual_result) do
    GenServer.cast(@name, {:record, id, category, decision, actual_result})
  end

  @doc "Get accuracy stats for a category."
  def stats(category) do
    GenServer.call(@name, {:stats, category})
  end

  @doc """
  Get recent outcomes for a category filtered by sub_key.

  Used by dispatcher to track healing success rates per bot name.
  Returns list of %{was_correct: bool, actual_result: string} maps, newest first, capped at limit.
  """
  def recent_outcomes(category, sub_key, limit) do
    GenServer.call(@name, {:recent_outcomes, category, sub_key, limit})
  end

  @doc "Reset all data (testing)."
  def reset do
    GenServer.cast(@name, :reset)
  end

  # ── GenServer Callbacks ─────────────────────────────────────

  @impl true
  def init(_opts) do
    # Load recent outcomes (last 30 days) from DB into in-memory state
    outcomes =
      try do
        load_recent_outcomes()
      rescue
        _ -> %{}
      end

    {:ok, %{outcomes: outcomes}}
  end

  defp load_recent_outcomes do
    import Ecto.Query

    thirty_days_ago = DateTime.add(DateTime.utc_now(), -30 * 24 * 60 * 60)

    BotArmyLearning.Repo.all(
      from(o in "learning_outcomes",
        where: o.recorded_at >= ^thirty_days_ago
      )
    )
    |> Enum.map(fn row ->
      {
        {row.category, row.item_id},
        %{
          id: row.item_id,
          category: row.category,
          decision: row.decision,
          actual_result: row.actual_result,
          was_correct: row.was_correct,
          recorded_at: row.recorded_at
        }
      }
    end)
    |> Map.new()
  rescue
    _ -> %{}
  end

  @impl true
  def handle_cast({:record, id, category, decision, actual_result}, state) do
    was_correct = correct?(decision, actual_result)
    now = DateTime.utc_now()

    outcome = %{
      id: id,
      category: category,
      decision: decision,
      actual_result: actual_result,
      was_correct: was_correct,
      recorded_at: now
    }

    # Persist to DB asynchronously (fire and forget)
    Task.start(fn -> persist_outcome(id, category, decision, actual_result, was_correct, now) end)

    new_state = put_in(state, [:outcomes, {category, id}], outcome)
    {:noreply, new_state}
  end

  @impl true
  def handle_cast(:reset, _state) do
    {:noreply, %{outcomes: %{}}}
  end

  defp persist_outcome(id, category, decision, actual_result, was_correct, recorded_at) do
    try do
      %BotArmyLearning.Schema.Outcome{
        item_id: id,
        category: category,
        decision: decision,
        actual_result: actual_result,
        was_correct: was_correct,
        recorded_at: recorded_at
      }
      |> BotArmyLearning.Repo.insert()
    rescue
      _ -> :ok
    end
  end

  @impl true
  def handle_call({:stats, category}, _from, state) do
    outcomes =
      state.outcomes
      |> Map.values()
      |> Enum.filter(&(&1.category == category))

    total = length(outcomes)
    correct = Enum.count(outcomes, & &1.was_correct)

    stats = %{
      total: total,
      correct: correct,
      accuracy: if(total > 0, do: correct / total, else: 0.0)
    }

    {:reply, stats, state}
  end

  @impl true
  def handle_call({:recent_outcomes, category, sub_key, limit}, _from, state) do
    outcomes =
      try do
        query_recent_outcomes(category, sub_key, limit)
      rescue
        _ ->
          state.outcomes
          |> Map.values()
          |> Enum.filter(
            &(&1.category == category and String.contains?(to_string(&1.id), sub_key))
          )
          |> Enum.sort_by(& &1.recorded_at, :desc)
          |> Enum.take(limit)
          |> Enum.map(&%{was_correct: &1.was_correct, actual_result: &1.actual_result})
      end

    {:reply, outcomes, state}
  end

  defp query_recent_outcomes(category, sub_key, limit) do
    import Ecto.Query

    BotArmyLearning.Repo.all(
      from(o in "learning_outcomes",
        where:
          o.category == ^category and
            fragment("? ILIKE ?", o.item_id, ^"%#{sub_key}%"),
        order_by: [desc: o.recorded_at],
        limit: ^limit,
        select: %{was_correct: o.was_correct, actual_result: o.actual_result}
      )
    )
  end

  # ── Helpers ─────────────────────────────────────────────────

  defp correct?("approved", "pass"), do: true
  defp correct?("approved", "fail"), do: false
  defp correct?("rejected", "fail"), do: true
  defp correct?("rejected", "pass"), do: false
  defp correct?("approved", "mixed"), do: false
  defp correct?("rejected", "mixed"), do: true
  defp correct?("approved", "timeout"), do: false
  defp correct?("rejected", "timeout"), do: true
  defp correct?("act", "success"), do: true
  defp correct?("act", "failure"), do: false
  defp correct?("defer", "failure"), do: true
  defp correct?("defer", "success"), do: false
  defp correct?(_, "timeout"), do: false
  defp correct?(_, _), do: false
end
