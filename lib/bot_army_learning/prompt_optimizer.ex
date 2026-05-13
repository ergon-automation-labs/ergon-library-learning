defmodule BotArmyLearning.PromptOptimizer do
  @moduledoc """
  Tracks prompt performance and suggests improvements.

  Records prompt variants with outcomes so consumers can learn which
  phrasing produces better results. Provides a rolling "best prompt"
  recommendation per task type.

  ## Usage

      BotArmyLearning.PromptOptimizer.record(
        "decomposition", prompt_text, score: 0.85, metadata: %{task_id: "t1"}
      )

      BotArmyLearning.PromptOptimizer.best_prompt("decomposition")
      # => %{prompt: "...", avg_score: 0.92, uses: 12}
  """

  use GenServer
  require Logger

  @name __MODULE__
  @max_variants_per_task 20

  # ── Client API ──────────────────────────────────────────────

  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name, @name)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @doc """
  Record a prompt variant with its outcome score.

  `score` is a float 0.0–1.0 (higher = better). Optional `metadata`
  can include any context the caller wants to keep.
  """
  def record(task_type, prompt_text, opts \\ []) do
    score = Keyword.get(opts, :score, 0.5)
    metadata = Keyword.get(opts, :metadata, %{})
    GenServer.cast(@name, {:record, task_type, prompt_text, score, metadata})
  end

  @doc """
  Get the best-performing prompt for a task type.

  Returns the prompt variant with the highest average score and at
  least 3 uses. If no variant qualifies, returns `nil`.
  """
  def best_prompt(task_type) do
    GenServer.call(@name, {:best_prompt, task_type})
  end

  @doc """
  List all prompt variants for a task type, sorted by avg_score desc.
  """
  def variants(task_type) do
    GenServer.call(@name, {:variants, task_type})
  end

  @doc "Reset all data (testing)."
  def reset do
    GenServer.cast(@name, :reset)
  end

  # ── GenServer Callbacks ───────────────────────────────────────

  @impl true
  def init(_opts) do
    {:ok, %{variants: %{}}}
  end

  @impl true
  def handle_cast({:record, task_type, prompt_text, score, metadata}, state) do
    key = {task_type, prompt_text}

    existing =
      get_in(state, [:variants, key]) ||
        %{
          task_type: task_type,
          prompt: prompt_text,
          total_score: 0.0,
          uses: 0,
          last_metadata: %{}
        }

    updated = %{
      existing
      | total_score: existing.total_score + score,
        uses: existing.uses + 1,
        last_metadata: metadata
    }

    new_state =
      state
      |> put_in([:variants, key], updated)
      |> prune_variants(task_type)

    {:noreply, new_state}
  end

  @impl true
  def handle_cast(:reset, _state) do
    {:noreply, %{variants: %{}}}
  end

  @impl true
  def handle_call({:best_prompt, task_type}, _from, state) do
    best =
      state.variants
      |> Map.values()
      |> Enum.filter(&(&1.task_type == task_type and &1.uses >= 3))
      |> Enum.sort_by(&(&1.total_score / &1.uses), :desc)
      |> List.first()

    result =
      if best do
        %{
          prompt: best.prompt,
          avg_score: best.total_score / best.uses,
          uses: best.uses
        }
      else
        nil
      end

    {:reply, result, state}
  end

  @impl true
  def handle_call({:variants, task_type}, _from, state) do
    variants =
      state.variants
      |> Map.values()
      |> Enum.filter(&(&1.task_type == task_type))
      |> Enum.map(
        &%{
          prompt: &1.prompt,
          avg_score: &1.total_score / &1.uses,
          uses: &1.uses
        }
      )
      |> Enum.sort_by(& &1.avg_score, :desc)

    {:reply, variants, state}
  end

  # ── Helpers ─────────────────────────────────────────────────

  defp prune_variants(state, task_type) do
    task_variants =
      state.variants
      |> Enum.filter(fn {_, v} -> v.task_type == task_type end)
      |> Enum.sort_by(fn {_, v} -> v.total_score / v.uses end, :desc)

    if length(task_variants) > @max_variants_per_task do
      to_drop = Enum.drop(task_variants, @max_variants_per_task)

      Enum.reduce(to_drop, state, fn {key, _}, acc ->
        update_in(acc, [:variants], &Map.delete(&1, key))
      end)
    else
      state
    end
  end
end
