defmodule Framework.Images.Image do
  use Ecto.Schema
  use Framework.AutoSlug
  import Ecto.Changeset
  #  import Ecto.Query

  #  alias Framework.Images.Image

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "images" do
    field :slug, :string
    field :link, :string
    field :filepath, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(event, attrs) do
    event
    |> cast(attrs, [
      :slug,
      :link
    ])
    |> validate_required([
      :link
    ])
  end
end
