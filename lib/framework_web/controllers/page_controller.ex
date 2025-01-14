defmodule FrameworkWeb.PageController do
  use FrameworkWeb, :controller

  def landing(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    render(conn, :landing, layout: false)
  end
end
