defmodule FrameworkWeb.UserRegistrationController do
  use FrameworkWeb, :controller

  alias Framework.Accounts
  alias Framework.Accounts.User
  alias FrameworkWeb.UserAuth
  alias FrameworkWeb.Router.Helpers, as: Routes

  def new(conn, _params) do
    changeset = Accounts.change_user_registration(%User{})
    render(conn, :new, error_message: nil, changeset: changeset)
  end

  def create(conn, user_params) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        {:ok, _} =
          Accounts.deliver_user_confirmation_instructions(
            user,
            &Routes.user_confirmation_url(conn, :confirm, &1),
            Application.get_env(:framework, :mode, :debug)
          )

        conn
        |> put_flash(:info, "User created successfully.")
        |> UserAuth.log_in_user(user)

      {:error, %Ecto.Changeset{} = changeset} ->
        IO.inspect(changeset, label: "changeset")
        render(conn, :new, changeset: changeset)
    end
  end
end
