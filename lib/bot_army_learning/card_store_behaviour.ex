defmodule BotArmyLearning.CardStoreBehaviour do
  @moduledoc """
  Behavior for card storage backends.

  Allows for flexible implementation: Ecto persistence, in-memory mocking, etc.
  """

  @callback list_cards_for_deck(deck_id :: String.t()) :: [map()]
  @callback list_due_cards(deck_id :: String.t(), limit :: integer()) :: [map()]
  @callback get_card(card_id :: String.t()) :: map() | nil
  @callback create_card(deck_id :: String.t(), attrs :: map()) :: {:ok, map()} | {:error, String.t()}
  @callback update_card(card_id :: String.t(), attrs :: map()) :: {:ok, map()} | {:error, String.t()}
  @callback delete_card(card_id :: String.t()) :: :ok | {:error, String.t()}
end
