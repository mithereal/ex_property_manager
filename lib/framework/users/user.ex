defmodule Framework.Users.User do
  use Ecto.Schema
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  import Ecto.Changeset

  alias Framework.Repo

  alias Framework.Users.User

  @derive {
    Flop.Schema,
    filterable: [:email, :last_login, :username, :active],
    sortable: [:email, :last_login, :username]
  }

  @derive {Inspect, except: [:password, :password_confirmation, :hashed_password]}
  schema "users" do
    field(:email, :string)
    field(:active, :boolean)
    field(:username, :string)
    field(:hashed_password, :string)
    field(:stripe_account_id, :string)
    field(:last_login, :naive_datetime)
    field(:confirmed_at, :naive_datetime)
    field(:theme, :string)

    belongs_to(:account, Framework.Accounts.Account)
    has_one(:profile, User.Profile)

    field(:password, :string, virtual: true)
    field(:password_confirmation, :string, virtual: true)
    field(:terms, :boolean, virtual: true)

    timestamps()
  end

  @doc """
  A user changeset for registration.

  It is important to validate the length of both email and password.
  Otherwise databases may truncate the email without warnings, which
  could lead to unpredictable or insecure behaviour. Long passwords may
  also be very expensive to hash for certain algorithms.
  """
  def registration_changeset(schema, attrs) do
    changeset =
      schema
      |> cast(attrs, [
        :email,
        :active,
        :password,
        :password_confirmation,
        :terms,
        :confirmed_at,
        :last_login,
        :username
      ])
      |> validate_email()
      |> validate_password()
      |> validate_required(:terms, message: "Do You Accept The Terms")
      |> validate_required([:password_confirmation])
      |> validate_confirmation(:password, message: "Passwords dont match")
      |> create_username()
      |> create_member()
      |> create_account()
  end

  def changeset(schema, attrs) do
    changeset =
      schema
      |> cast(attrs, [
        :email,
        :password,
        :username,
        :terms,
        :stripe_account_id,
        :account_id,
        :profile_id,
        :membership_id
      ])
      |> validate_email()
      |> validate_password()
  end

  defp create_account(%{valid?: true} = changeset) do
    {:ok, account} =
      %Framework.Accounts.Account{email: changeset.changes.email} |> Framework.Repo.insert()

    changeset
    |> put_change(:account_id, account.id)
  end

  defp create_role(changeset) do
    %{changeset | valid?: false}
  end

  defp create_member(changeset) do
    %{changeset | valid?: false}
  end

  defp create_account(changeset) do
    %{changeset | valid?: false}
  end

  defp create_username(%{valid?: true} = changeset) do
    changeset
    |> put_change(:username, changeset.changes.email)
  end

  defp create_username(changeset) do
    changeset
  end

  defp validate_email(changeset) do
    changeset
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> validate_length(:email, max: 160)
    |> unsafe_validate_unique(:email, Framework.Repo)
    |> unique_constraint(:email)
  end

  defp validate_password(changeset) do
    changeset
    |> validate_required([:password])
    |> validate_length(:password, min: 5, max: 80)
    # |> validate_format(:password, ~r/[a-z]/, message: "at least one lower case character")
    # |> validate_format(:password, ~r/[A-Z]/, message: "at least one upper case character")
    # |> validate_format(:password, ~r/[!?@#$%^&*_0-9]/, message: "at least one digit or punctuation character")
    |> prepare_changes(&hash_password/1)
  end

  defp hash_password(changeset) do
    password = get_change(changeset, :password)

    changeset
    |> put_change(:hashed_password, Bcrypt.hash_pwd_salt(password))
    |> delete_change(:password)
  end

  @doc """
  A user changeset for changing the email.

  It requires the email to change otherwise an error is added.
  """
  def email_changeset(user, attrs) do
    user
    |> cast(attrs, [:email])
    |> validate_email()
    |> case do
      %{changes: %{email: _}} = changeset -> changeset
      %{} = changeset -> add_error(changeset, :email, "did not change")
    end
  end

  @doc """
  A user changeset for changing the password.
  """
  def password_changeset(user, attrs) do
    user
    |> cast(attrs, [:password])
    |> validate_confirmation(:password, message: "does not match password")
    |> validate_password()
  end

  @doc """
  Confirms the account by setting `confirmed_at`.
  """
  def confirm_changeset(user) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    change(user, confirmed_at: now)
  end

  @doc """
  Verifies the password.

  If there is no user or the user doesn't have a password, we call
  `Bcrypt.no_user_verify/0` to avoid timing attacks.
  """
  def valid_password?(%User{hashed_password: hashed_password}, password)
      when is_binary(hashed_password) and byte_size(password) > 0 do
    Bcrypt.verify_pass(password, hashed_password)
  end

  def valid_password?(%User{hashed_password: hashed_password}, password)
      when byte_size(hashed_password) < 1 do
    nil
  end

  def valid_password?(_, _) do
    Bcrypt.no_user_verify()
    false
  end

  @doc """
  Validates the current password otherwise adds an error to the changeset.
  """
  def validate_current_password(changeset, password) do
    if valid_password?(changeset.data, password) do
      changeset
    else
      add_error(changeset, :current_password, "is not valid")
    end
  end

  def get_user(email) do
    Repo.get_by(User, email: email)
    |> Repo.preload(:profile)
  end

  def update_user(data) do
    Repo.update(User, data)
  end

  def delete_user(user) do
    Repo.delete(User, user)
  end

  def delete_user_by_email(email) do
    Repo.delete(User, email)
  end

  def update_user(id, data) do
    Repo.get_by(User, id: id)
    |> Repo.update(data)
  end

  def delete_all_users do
    # the logic for deleting all the accounts ...
  end
end
