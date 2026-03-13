defmodule BotArmyLearning.Schemas.Domain do
  @moduledoc """
  Learning domain schema.

  A domain groups related decks (e.g., 'greek_language', 'mathematics').
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "learning_domains" do
    field :name, :string
    field :description, :string

    has_many :decks, BotArmyLearning.Schemas.Deck

    timestamps()
  end

  def changeset(domain, attrs) do
    domain
    |> cast(attrs, [:name, :description])
    |> validate_required([:name])
  end
end
