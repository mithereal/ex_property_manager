defmodule FrameworkWeb.RedirectController do
  use FrameworkWeb, :controller

  alias FrameworkWeb.PageController

  import FrameworkWeb.UserAuth, only: [fetch_current_user: 2]

  plug :fetch_current_user

  def redirect_authenticated(conn, _) do
    if conn.assigns.current_user do
      FrameworkWeb.UserAuth.redirect_if_user_is_authenticated(conn, [])
    else
      PageController.landing(conn, [])
    end
  end
end
