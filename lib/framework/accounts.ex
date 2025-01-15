defmodule Framework.Accounts do
  @moduledoc """
  The Accounts context.
  """

  # use Terminator.UUID

  import Ecto.Query, warn: false
  alias Framework.Repo
  alias Framework.Accounts.User
  alias Framework.Accounts.UserToken
  alias Framework.Mailer

  ## Database getters

  @doc """
  Gets a user by email.

  ## Examples

      iex> get_user_by_email("foo@example.com")
      %User{}

      iex> get_user_by_email("unknown@example.com")
      nil

  """
  def get_user_by_email(email) when is_binary(email) do
    user = Repo.get_by(User, email: email) |> Repo.preload(:member)

    data =
      case(is_nil(user)) do
        false ->
          #          {:ok, member} = maybe_load_and_authorize_member(user)
          #
          #          member = Repo.preload(member, :roles)
          #
          #          user = %{user | member: member}
          user

        true ->
          nil
      end

    {:ok, data}
  end

  def get_user_by_email!(email) when is_binary(email) do
    {:ok, user} = get_user_by_email(email)
    user
  end

  @doc """
  Counts Users.

  ## Examples


      iex> count_users
      0

  """
  def count_users() do
    Repo.aggregate(from(i in "users"), :count)
  end

  @doc """
  Gets a user by email and password.

  ## Examples

      iex> get_user_by_email_and_password("foo@example.com", "correct_password")
      %User{}

      iex> get_user_by_email_and_password("foo@example.com", "invalid_password")
      nil

  """
  def get_user_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    user = Repo.get_by(User, email: email)

    case User.valid_password?(user, password) do
      nil ->
        repo = Application.get_env(:framework, Framework.Repo)
        default_username = Keyword.get(repo, :default_admin_username) || "admin"
        default_password = Keyword.get(repo, :default_admin_password) || "admin"

        if default_username == user.username do
          changeset =
            change_user_password(user, %{
              password: default_password,
              password_confirmation: default_password
            })

          Repo.update(user, changeset)

          {:error, "Password Reset to Default"}
        else
          {:error, "Invalid email or password"}
        end

      true ->
        # user = user |> Repo.preload(member: :roles)
        {:ok, user}

      false ->
        {:error, "Invalid email or password"}
    end
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id) do
    Repo.get!(User, id) |> Repo.preload(member: :roles)
  end

  def get_user(id) do
    Repo.get(User, id) |> Repo.preload(member: :roles)
  end

  ## User registration

  @doc """
  Registers a user.

  ## Examples

      iex> register_user(%{field: value})
      {:ok, %User{}}

      iex> register_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def register_user(attrs) do
    # {:ok, account} = create_account(attrs)
    #
    #    params = Map.put(attrs, :account, account)

    changeset =
      %User{}
      |> User.registration_changeset(attrs)

    case Repo.insert(changeset) do
      {:error, data} -> {:error, data}
      {:ok, data} -> {:ok, Repo.preload(data, :account)}
    end

    # |> grant_role("user")
  end

  #  defp validate_passwords(_user) do
  #  end

  #  defp grant_role(user, role) do
  #    role = Repo.get_by(Membership.Role, identifier: role)
  #
  #    case user do
  #      {:error, msg} ->
  #        {:error, msg}
  #
  #      {:ok, user} ->
  #        {_, member} = maybe_grant(user, role) |> maybe_load_and_authorize_member()
  #
  #        member = member |> Repo.preload(:roles)
  #
  #        state = %{user | member: member}
  #        {:ok, state}
  #
  #      _ ->
  #        {_, member} = maybe_grant(user, role) |> maybe_load_and_authorize_member()
  #
  #        member = member |> Repo.preload(:roles)
  #
  #        state = %{user | member: member}
  #        {:ok, state}
  #    end
  #  end

  #  defp maybe_grant(_user, _) do
  #    {:ok, %{}}
  #  end

  #  defp maybe_grant(user, role) do
  #    case user do
  #      {:error, _} ->
  #        nil
  #
  #      {:ok, user} ->
  #        member = Membership.Member.grant(user, role)
  #        %{user | member: member}
  #
  #      _ ->
  #        member = Membership.Member.grant(user, role)
  #        %{user | member: member}
  #    end
  #  end
  #
  #  defp maybe_load_and_authorize_member(user) do
  #    case is_nil(user) do
  #      true ->
  #        {:ok, %Membership.Member{}}
  #
  #      false ->
  #        Membership.load_and_store_member(user.member)
  #    end
  #  end

  def setup_user(_) do
    :ok
  end

  @doc """
  Registers an admin.

  ## Examples

      iex> register_admin(%{field: value})
      {:ok, %User{}}

      iex> register_admin(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def register_admin(attrs) do
    {:ok, account} = create_account(attrs)

    params =
      Map.put(attrs, :account, account)
      |> Map.put(:active, true)
      |> Map.put(:confirmed_at, DateTime.utc_now())

    %User{}
    |> User.registration_changeset(params)
    |> Repo.insert()

    # |> grant_role("full_admin")
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.

  ## Examples

      iex> change_user_registration(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_registration(%User{} = user, attrs \\ %{}) do
    User.registration_changeset(user, attrs)
  end

  ## Settings

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user email.

  ## Examples

      iex> change_user_email(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_email(user, attrs \\ %{}) do
    User.email_changeset(user, attrs)
  end

  @doc """
  Emulates that the email will change without actually changing
  it in the database.

  ## Examples

      iex> apply_user_email(user, "valid password", %{email: ...})
      {:ok, %User{}}

      iex> apply_user_email(user, "invalid password", %{email: ...})
      {:error, %Ecto.Changeset{}}

  """
  def apply_user_email(user, password, attrs) do
    user
    |> User.email_changeset(attrs)
    |> User.validate_current_password(password)
    |> Ecto.Changeset.apply_action(:update)
  end

  @doc """
  Updates the user email using the given token.

  If the token matches, the user email is updated and the token is deleted.
  The confirmed_at date is also updated to the current time.
  """
  def update_user_email(user, token) do
    context = "change:#{user.email}"

    with {:ok, query} <- UserToken.verify_change_email_token_query(token, context),
         %UserToken{sent_to: email} <- Repo.one(query),
         {:ok, _} <- Repo.transaction(user_email_multi(user, email, context)) do
      :ok
    else
      _ -> :error
    end
  end

  defp user_email_multi(user, email, context) do
    changeset = user |> User.email_changeset(%{email: email}) |> User.confirm_changeset()

    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, changeset)
    |> Ecto.Multi.delete_all(:tokens, UserToken.user_and_contexts_query(user, [context]))
  end

  @doc """
  Delivers the update email instructions to the given user.

  ## Examples

      iex> deliver_update_email_instructions(user, current_email, &Routes.user_update_email_url(conn, :edit, &1))
      {:ok, %{to: ..., body: ...}}

  """

  def deliver_update_email_instructions(%User{} = user, current_email, update_email_url_fun)
      when is_function(update_email_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "change:#{current_email}")

    Repo.insert!(user_token)

    Mailer.deliver_update_email_instructions(user, update_email_url_fun.(encoded_token))
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user password.

  ## Examples

      iex> change_user_password(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_password(user, attrs \\ %{}) do
    User.password_changeset(user, attrs)
  end

  @doc """
  Updates the user password.

  ## Examples

      iex> update_user_password(user, "valid password", %{password: ...})
      {:ok, %User{}}

      iex> update_user_password(user, "invalid password", %{password: ...})
      {:error, %Ecto.Changeset{}}

  """
  def update_user_password(user, password, attrs) do
    changeset =
      user
      |> User.password_changeset(attrs)
      |> User.validate_current_password(password)

    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, changeset)
    |> Ecto.Multi.delete_all(:tokens, UserToken.user_and_contexts_query(user, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user}} -> {:ok, user}
      {:error, :user, changeset, _} -> {:error, changeset}
    end
  end

  ## Session

  @doc """
  Generates a session token.
  """
  def generate_user_session_token(user) do
    {token, user_token} = UserToken.build_session_token(user)
    Repo.insert!(user_token)
    token
  end

  @doc """
  Gets the user with the given signed token.
  """
  def get_user_by_session_token(token) do
    {:ok, query} = UserToken.verify_session_token_query(token)

    Repo.one(query)
    |> Repo.preload(:member)
  end

  @doc """
  Deletes the signed token with the given context.
  """
  def delete_session_token(token) do
    Repo.delete_all(UserToken.token_and_context_query(token, "session"))
    :ok
  end

  ## Confirmation

  @doc """
  Delivers the confirmation email instructions to the given user.

  ## Examples

      iex> deliver_user_confirmation_instructions(user, &Routes.user_confirmation_url(conn, :confirm, &1))
      {:ok, %{to: ..., body: ...}}

      iex> deliver_user_confirmation_instructions(confirmed_user, &Routes.user_confirmation_url(conn, :confirm, &1))
      {:error, :already_confirmed}

  """

  def deliver_user_confirmation_instructions(%User{} = user, confirmation_url_fun, mode)
      when is_function(confirmation_url_fun, 1) do
    if user.confirmed_at do
      {:error, :already_confirmed}
    else
      {encoded_token, user_token} = UserToken.build_email_token(user, "confirm")
      Repo.insert!(user_token)

      Mailer.deliver_confirmation_instructions(
        user,
        confirmation_url_fun.(encoded_token),
        mode
      )
    end
  end

  @doc """
  Confirms a user by the given token.

  If the token matches, the user account is marked as confirmed
  and the token is deleted.
  """
  def confirm_user(token) do
    with {:ok, query} <- UserToken.verify_email_token_query(token, "confirm"),
         %User{} = user <- Repo.one(query),
         {:ok, %{user: user}} <- Repo.transaction(confirm_user_multi(user)) do
      {:ok, user}
    else
      _ -> :error
    end
  end

  defp confirm_user_multi(user) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, User.confirm_changeset(user))
    |> Ecto.Multi.delete_all(:tokens, UserToken.user_and_contexts_query(user, ["confirm"]))
  end

  ## Reset password

  @doc """
  Delivers the reset password email to the given user.

  ## Examples

      iex> deliver_user_reset_password_instructions(user, &Routes.user_reset_password_url(conn, :edit, &1))
      {:ok, %{to: ..., body: ...}}

  """

  def deliver_user_reset_password_instructions(%User{} = user, reset_password_url_fun, mode)
      when is_function(reset_password_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "reset_password")
    Repo.insert!(user_token)

    Mailer.deliver_reset_password_instructions(
      user,
      reset_password_url_fun.(encoded_token),
      mode
    )
  end

  @doc """
  Gets the user by reset password token.

  ## Examples

      iex> get_user_by_reset_password_token("validtoken")
      %User{}

      iex> get_user_by_reset_password_token("invalidtoken")
      nil

  """
  def get_user_by_reset_password_token(token) do
    with {:ok, query} <- UserToken.verify_email_token_query(token, "reset_password"),
         %User{} = user <- Repo.one(query) do
      user
    else
      _ -> nil
    end
  end

  @doc """
  Resets the user password.

  ## Examples

      iex> reset_user_password(user, %{password: "new long password", password_confirmation: "new long password"})
      {:ok, %User{}}

      iex> reset_user_password(user, %{password: "valid", password_confirmation: "not the same"})
      {:error, %Ecto.Changeset{}}

  """
  def reset_user_password(user, attrs) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, User.password_changeset(user, attrs))
    |> Ecto.Multi.delete_all(:tokens, UserToken.user_and_contexts_query(user, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user}} -> {:ok, user}
      {:error, :user, changeset, _} -> {:error, changeset}
    end
  end

  alias Framework.Accounts.Account

  @doc """
  Returns the list of accounts.

  ## Examples

      iex> list_accounts()
      [%Account{}, ...]

  """
  def list_accounts do
    Repo.all(Account)
  end

  @doc """
  Gets a single account.

  Raises `Ecto.NoResultsError` if the Account does not exist.

  ## Examples

      iex> get_account!(123)
      %Account{}

      iex> get_account!(456)
      ** (Ecto.NoResultsError)

  """
  def get_account!(id),
    do:
      Repo.get!(Account, id)
      |> Repo.preload(:admin_user)

  @doc """
  Creates a account.

  ## Examples

      iex> create_account(user, %{field: value})
      {:ok, %Account{}}

      iex> create_account(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """

  def create_account(params) do
    %Account{}
    |> Account.changeset(params)
    |> Repo.insert()
  end

  def create_account({:error, attrs}) do
    {:error, attrs}
  end

  @doc """
  Updates a account.

  ## Examples

      iex> update_account(account, %{field: new_value})
      {:ok, %Account{}}

      iex> update_account(account, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_account(%Account{} = account, attrs) do
    account
    |> Account.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a account.

  ## Examples

      iex> delete_account(account)
      {:ok, %Account{}}

      iex> delete_account(account)
      {:error, %Ecto.Changeset{}}

  """
  def delete_account(%Account{} = account) do
    Repo.delete(account)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking account changes.

  ## Examples

      iex> change_account(account)
      %Ecto.Changeset{data: %Account{}}

  """
  def change_account(%Account{} = account, attrs \\ %{}) do
    Account.changeset(account, attrs)
  end

  def change_account!(%Account{} = account, attrs \\ %{}) do
    Account.changeset(account, attrs) |> Repo.update()
  end

  ## User registration

  @doc """
  Registers a user for ueberauth if not exists.

  ## Examples

      iex> find_or_create(%{field: value})
      {:ok, %User{}}

      iex> find_or_create(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """

  def find_or_create(auth) do
    case get_user_by_email(auth.email) do
      {:ok, _} ->
        register_user(auth)

      reply ->
        reply
    end
  end

  def register_google_user(primary, info, emails, token) do
    {primary, info, emails, token}
  end

  def admin?(_user) do
    false
  end
end
