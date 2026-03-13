defmodule BotArmyLearning.CardStore do
  @moduledoc """
  In-memory card store with Ecto persistence.

  Manages flashcard data, caches in memory, and persists to PostgreSQL.
  """

  use GenServer
  require Logger
  import Ecto.Query

  alias BotArmyLearning.Repo
  alias BotArmyLearning.Schemas.Card

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    Logger.info("CardStore starting...")
    {:ok, %{}}
  end

  @doc """
  List all cards in a deck.
  """
  def list_cards_for_deck(deck_id) do
    GenServer.call(__MODULE__, {:list_cards_for_deck, deck_id})
  end

  @doc """
  List cards due for review in a deck (limited to card_limit).
  """
  def list_due_cards(deck_id, limit \\ 20) do
    GenServer.call(__MODULE__, {:list_due_cards, deck_id, limit})
  end

  @doc """
  Get a single card by ID.
  """
  def get_card(card_id) do
    GenServer.call(__MODULE__, {:get_card, card_id})
  end

  @doc """
  Create a new card.
  """
  def create_card(deck_id, attrs) do
    GenServer.call(__MODULE__, {:create_card, deck_id, attrs})
  end

  @doc """
  Update an existing card.
  """
  def update_card(card_id, attrs) do
    GenServer.call(__MODULE__, {:update_card, card_id, attrs})
  end

  @doc """
  Delete a card.
  """
  def delete_card(card_id) do
    GenServer.call(__MODULE__, {:delete_card, card_id})
  end

  # GenServer callbacks

  @impl true
  def handle_call({:list_cards_for_deck, deck_id}, _from, state) do
    cards = Repo.all(from(c in Card, where: c.deck_id == ^deck_id))
    {:reply, cards, state}
  end

  @impl true
  def handle_call({:list_due_cards, deck_id, limit}, _from, state) do
    today = Date.utc_today()

    cards =
      Repo.all(
        from(c in Card,
          where: c.deck_id == ^deck_id and c.due_at <= ^today,
          limit: ^limit
        )
      )

    {:reply, cards, state}
  end

  @impl true
  def handle_call({:get_card, card_id}, _from, state) do
    card = Repo.get(Card, card_id)
    {:reply, card, state}
  end

  @impl true
  def handle_call({:create_card, deck_id, attrs}, _from, state) do
    result =
      Card.changeset(%Card{}, Map.merge(attrs, %{"deck_id" => deck_id}))
      |> Repo.insert()

    {:reply, result, state}
  end

  @impl true
  def handle_call({:update_card, card_id, attrs}, _from, state) do
    card = Repo.get(Card, card_id)

    if card do
      result = Card.changeset(card, attrs) |> Repo.update()
      {:reply, result, state}
    else
      {:reply, {:error, "Card not found"}, state}
    end
  end

  @impl true
  def handle_call({:delete_card, card_id}, _from, state) do
    card = Repo.get(Card, card_id)

    if card do
      case Repo.delete(card) do
        {:ok, _} -> {:reply, :ok, state}
        {:error, reason} -> {:reply, {:error, reason}, state}
      end
    else
      {:reply, {:error, "Card not found"}, state}
    end
  end
end
