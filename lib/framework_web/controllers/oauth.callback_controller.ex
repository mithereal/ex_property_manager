defmodule FrameworkWeb.OAuthCallbackController do
  use FrameworkWeb, :controller
  require Logger

  alias Framework.Accounts

  def new(conn, %{"provider" => "google", "code" => code, "state" => state}) do
    client = google_client(conn)

    with {:ok, info} <- client.exchange_access_token(code: code, state: state),
         %{info: info, primary_email: primary, emails: emails, token: token} = info,
         {:ok, user} <- Accounts.register_google_user(primary, info, emails, token) do
      conn
      |> put_flash(:info, "Welcome #{user.email}")
      |> FrameworkWeb.UserAuth.log_in_user(user)
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        Logger.info("failed Google insert #{inspect(changeset.errors)}")

        conn
        |> put_flash(
          :error,
          "We were unable to fetch the necessary information from your Google account"
        )
        |> redirect(to: "/")

      {:error, reason} ->
        Logger.info("failed Google exchange #{inspect(reason)}")

        conn
        |> put_flash(:error, "We were unable to contact Google. Please try again later")
        |> redirect(to: "/")
    end
  end

  def new(conn, %{"provider" => "google", "error" => "access_denied"}) do
    redirect(conn, to: "/")
  end

  def sign_out(conn, _) do
    FrameworkWeb.UserAuth.log_out_user(conn)
  end

  defp google_client(conn) do
    conn.assigns[:google_client] || Framework.Google
  end
end
