defmodule BotArmyLearning.Schemas.Deck do
  @moduledoc """
  Learning deck schema.

  A deck contains a collection of flashcards for learning a specific topic.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "learning_decks" do
    field :name, :string
    field :description, :string
    field :card_count, :integer, default: 0

    belongs_to :domain, BotArmyLearning.Schemas.Domain
    has_many :cards, BotArmyLearning.Schemas.Card
    has_many :sessions, BotArmyLearning.Schemas.Session

    timestamps()
  end

  def changeset(deck, attrs) do
    deck
    |> cast(attrs, [:name, :description, :domain_id, :card_count])
    |> validate_required([:name, :domain_id])
  end
end
