defmodule Framework.Repo.Migrations.CreateUserProfiles do
  use Ecto.Migration

  def change do
    create table(:user_profiles, primary_key: false) do
      add :id, :uuid, primary_key: true
      add(:name, :string)
      add(:email, :string)
      add(:phone, :string)
      add(:phone_alt, :string)
      add(:address, :string)
      add(:mailing_address, :string)
      add(:city, :string)
      add(:state, :string)
      add(:zip, :string)
      add(:image, :string)
      add(:about, :string)

      add(:user_id, references(:users, on_delete: :nothing, type: :uuid))

      timestamps()
    end
  end

  def down do
    execute("DROP user_profiles")
  end
end
