defmodule Framework.Repo.Migrations.CreateAccounts do
  use Ecto.Migration

  def change do
    create table(:accounts, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :email, :string
      add :active, :boolean, default: false, null: false

      add(:admin_user_id, references(:users, on_delete: :nothing, type: :uuid))

      timestamps(type: :utc_datetime)
    end

    alter table(:users) do
      add(:account_id, references(:accounts, on_delete: :nothing, type: :uuid))
    end
  end
end
