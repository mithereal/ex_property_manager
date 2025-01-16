defmodule Framework.Admin do
  @moduledoc """
  The Admin context.
  """
  use Phoenix.Channel, topic: "Admin"

  import Ecto.Query, warn: false
  alias Framework.Repo

  alias Framework.Accounts.User, as: USER
  alias Framework.User.Server, as: SERVER

  @doc """
  Returns the list of users.

  ## Examples

      iex> list_users()
      [%User{}, ...]

  """
  def list_users(limit \\ 6) do
    hash_list = Framework.User.Server.Supervisor.list()

    Enum.map(hash_list, fn x ->
      {_, user} = Framework.User.Server.show(x)
      user
    end)
  end

  def refresh_users() do
    users = list_users()
    total_users = Framework.Accounts.count_users()
    params = %{active_users: users, total_users: total_users}

    broadcast({:ok, params}, "Admin", "Dashboard")
    broadcast({:ok, params}, "Admin", "Users")
  end


  def list_db_users(limit \\ 6) do
    hash_list = Framework.User.Server.Supervisor.list()

    Enum.map(hash_list, fn x ->
      {_, user} = Framework.User.Server.show(x)
      user
    end)
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the Game does not exist.

  ## Examples

      iex> get_user!(123)
      %Game{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user(hash) do
    SERVER.show(hash)
  end

  @doc """
  Creates a user.

  ## Examples

      iex> create_user(%{field: value})
      {:ok, %USER{}}

      iex> create_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_user(attrs \\ %{}) do
    Framework.User.Server.Supervisor.start(attrs)

    # %USER{}
    # |> USER.changeset(attrs)
    # |> Repo.insert()
  end

  @doc """
  Updates a USER.

  ## Examples

      iex> update_user(user, %{field: new_value})
      {:ok, %User{}}

      iex> update_user(user, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_user(%USER{} = user, attrs) do
    user
    |> USER.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a User.

  ## Examples

      iex> delete_user(user)
      {:ok, %User{}}

      iex> delete_user(user)
      {:error, %Ecto.Changeset{}}

  """
  def delete_user(id) do
    Framework.User.Server.Supervisor.stop(id)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.

  ## Examples

      iex> change_user(user)
      %Ecto.Changeset{source: %User{}}

  """
  def change_user(%USER{} = user) do
    USER.changeset(user, %{})
  end
end
