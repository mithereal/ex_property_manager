defmodule Framework.Accounts.User do
  use Ecto.Schema
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  import Ecto.Changeset

  alias Framework.Repo
  alias Framework.Accounts.User
  alias Framework.Accounts.Identity

  @derive {
    Flop.Schema,
    filterable: [:email, :active, :username, :last_login], sortable: [:last_login]
  }

  @derive {Inspect, except: [:password, :hashed_password, :password_confirmation]}
  schema "users" do
    field(:email, :string)
    field(:active, :boolean)
    field(:username, :string)
    field(:password, :string, virtual: true)
    field(:hashed_password, :string)
    field(:last_login, :naive_datetime)
    field(:confirmed_at, :naive_datetime)
    field(:password_confirmation, :string, virtual: true)
    field(:theme, :string, default: "light")

    belongs_to(:account, Framework.Accounts.Account)
    has_one(:profile, Framework.Users.User.Profile)
    #    belongs_to(:member, Membership.Member)

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
    schema
    |> cast(attrs, [
      :email,
      :active,
      :password,
      :password_confirmation,
      :confirmed_at,
      :last_login,
      :username
    ])
    |> validate_email()
    |> validate_password()
    |> validate_required([:password_confirmation])
    |> validate_confirmation(:password, message: "Passwords dont match")
    |> create_username()
    |> create_account()

    #    |> create_member()
  end

  def changeset(schema, attrs) do
    schema
    |> cast(attrs, [
      :email,
      :password,
      :account,
      :username,
      :active,
      :last_login,
      :confirmed_at
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

  defp set_default_theme(%{valid?: true} = changeset) do
    changeset
    |> put_change(:theme, "light")
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
  def valid_password?(%Framework.Users.User{hashed_password: hashed_password}, password)
      when is_binary(hashed_password) and byte_size(password) > 0 do
    Bcrypt.verify_pass(password, hashed_password)
  end

  def valid_password?(%Framework.Users.User{hashed_password: hashed_password}, _password)
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

  def get_user(hash) do
    Repo.get_by(Framework.Users.User, id: hash)
    |> Repo.preload(:profile)
  end

  def update_user(data) do
    Repo.update(Framework.Users.User, data)
  end

  def update_user(hash, data) do
    Repo.get_by(Framework.Users.User, id: hash)
    |> Repo.update(data)
  end

  @doc """
  A user changeset for github registration.
  """
  def github_registration_changeset(info, primary_email, emails, token) do
    %{"login" => username, "avatar_url" => avatar_url, "html_url" => external_homepage_url} = info

    identity_changeset =
      Identity.github_registration_changeset(info, primary_email, emails, token)

    if identity_changeset.valid? do
      params = %{
        "username" => username,
        "email" => primary_email,
        "name" => get_change(identity_changeset, :provider_name),
        "avatar_url" => avatar_url,
        "external_homepage_url" => external_homepage_url
      }

      %User{}
      |> cast(params, [:email, :username])
      |> validate_required([:email, :username])
      |> validate_email()
      |> put_assoc(:identities, [identity_changeset])
    else
      %User{}
      |> change()
      |> Map.put(:valid?, false)
      |> put_assoc(:identities, [identity_changeset])
    end
  end
end
