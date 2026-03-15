defmodule BotArmyLearning.Formatter do
  @moduledoc """
  Message formatting for Learning Bot non-LLM notifications.

  Formats review reminders, deck updates, and learning milestone notifications
  with Learning Bot's curious guide voice.

  Reference: `/docs/north_star_docs/BOT_ARMY_PERSONALITY_NORTH_STAR.md`
  """

  require Logger
  alias BotArmyRuntime.Personality.Formatter

  @doc """
  Format review ready notification.

  Used when cards are ready for review.
  """
  def format(:review_ready, %{"deck_name" => deck, "card_count" => count}) do
    Formatter.with_symbol(
      :learning_bot,
      "#{deck}: #{count} card#{if count == 1, do: "", else: "s"} ready for review."
    )
  end

  @doc """
  Format streak milestone notification.

  Used when a learning streak reaches a milestone.
  """
  def format(:streak_milestone, %{"days" => days, "deck_name" => deck}) do
    Formatter.with_symbol(
      :learning_bot,
      "#{days} day streak on #{deck}. That's where the learning lives."
    )
  end

  @doc """
  Format deck created notification.

  Used when a new deck is created.
  """
  def format(:deck_created, %{"deck_name" => name}) do
    Formatter.with_symbol(
      :learning_bot,
      "New deck: #{name}. Good. You're pushing into discomfort."
    )
  end

  @doc """
  Format progress update notification.

  Used to report progress in mastery of a deck.
  """
  def format(:progress_update, %{"deck_name" => deck, "mastered_count" => mastered, "total_count" => total}) do
    percentage = if total > 0, do: div(mastered * 100, total), else: 0
    Formatter.with_symbol(
      :learning_bot,
      "#{deck}: #{mastered}/#{total} mastered (#{percentage}%). Keep going."
    )
  end

  @doc """
  Format card feedback notification.

  Used when a card review is processed.
  """
  def format(:card_reviewed, %{"deck_name" => deck, "difficulty" => difficulty}) do
    msg = case difficulty do
      difficulty when difficulty <= 2 -> "That one's still hard. Keep wrestling with it."
      difficulty when difficulty <= 3 -> "Getting there. One more review cycle."
      _ -> "You've got it. Moving forward."
    end
    Formatter.with_symbol(:learning_bot, "#{deck}: #{msg}")
  end

  @doc """
  Format error notification.

  Used when something goes wrong.
  """
  def format(:error, %{"message" => message}) do
    Formatter.with_symbol(:learning_bot, "Something went wrong: #{message}")
  end

  def format(_type, _data) do
    Logger.warning("Unknown Learning formatter type")
    Formatter.with_symbol(:learning_bot, "Something happened.")
  end
end
