defmodule Framework.Accounts.Identity do
  use Ecto.Schema
  import Ecto.Changeset

  alias Framework.Accounts.{Identity, User}

  @derive {
    Flop.Schema,
    filterable: [:provider, :provider_name, :provider_login, :provider_id], sortable: [:provider]
  }

  # providers
  @google "google"

  @derive {Inspect, except: [:provider_token, :provider_meta]}
  schema "identities" do
    field :provider, :string
    field :provider_token, :string
    field :provider_email, :string
    field :provider_login, :string
    field :provider_name, :string, virtual: true
    field :provider_id, :string
    field :provider_meta, :map

    belongs_to :user, User

    timestamps()
  end

  @doc """
  A user changeset for google registration.
  """
  def google_registration_changeset(info, primary_email, emails, token) do
    params = %{
      "provider_token" => token,
      "provider_id" => to_string(info["id"]),
      "provider_login" => info["login"],
      "provider_name" => info["name"] || info["login"],
      "provider_email" => primary_email
    }

    %Identity{provider: @google, provider_meta: %{"user" => info, "emails" => emails}}
    |> cast(params, [
      :provider_token,
      :provider_email,
      :provider_login,
      :provider_name,
      :provider_id
    ])
    |> validate_required([:provider_token, :provider_email, :provider_name, :provider_id])
    |> validate_length(:provider_meta, max: 10_000)
  end
end
