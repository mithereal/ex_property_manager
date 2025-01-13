defmodule Framework.Accounts.Account do
  use Ecto.Schema
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  import Ecto.Changeset

  @derive {
    Flop.Schema,
    filterable: [:email, :active], sortable: [:email]
  }

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "accounts" do
    field(:email, :string)
    field(:active, :boolean)

    has_one(:admin_user, Framework.Accounts.User)
    has_many(:users, Framework.Accounts.User)

    timestamps()
  end

  @doc false
  def changeset(account, attrs) do
    account
    |> cast(attrs, [:email, :active])
    |> validate_required([:email])
  end

  @doc false
  def changeset(account, attrs, :admin) do
    account
    |> cast(attrs, [:email])
    |> validate_required([:email])
    |> cast_assoc(:admin_user)
    |> changeset_preload(:admin_user)
    |> put_assoc_nochange(:admin_user, %{})
  end

  def changeset_preload(ch, field),
    do: update_in(ch.data, &Repo.preload(&1, field))

  def put_assoc_nochange(ch, field, new_change) do
    case get_change(ch, field) do
      nil -> put_assoc(ch, field, new_change)
      _ -> ch
    end
  end
end
