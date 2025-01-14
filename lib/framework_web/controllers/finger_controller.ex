defmodule FrameworkWeb.FingerController do
  use FrameworkWeb, :controller

  @aliases ["acct:mithereal@data-twister.com", "acct:mithereal@gmail.com"]

  plug ETag.Plug
  plug :resource_required

  def finger(conn, %{"resource" => resource}) do
    case resource do
      r when r in @aliases ->
        data = %{
          subject: "acct:mithereal@data-twister.com",
          aliases: [
            "acct:mithereal@gmail.com",
            "https://profile.codersrank.io/user/mithereal",
            "https://github.com/mithereal"
          ],
          links: [
            %{
              rel: "http://webfinger.net/rel/profile-page",
              type: "text/html",
              href: "https://github.com/mithereal"
            },
            %{
              rel: "self",
              type: "application/activity+json",
              href: "https://api.github.com/users/mithereal"
            },
            %{
              rel: "self",
              href: "https://profile.codersrank.io/user/mithereal"
            },
            %{
              rel: "self",
              href: "https://data-twister.com"
            }
          ]
        }

        response = Phoenix.json_library().encode_to_iodata!(data)

        conn
        |> put_resp_content_type("application/jrd+json")
        |> send_resp(200, response)

      _ ->
        send_resp(conn, :not_found, "")
    end
  end

  defp resource_required(conn, _) do
    if conn.query_params["resource"] do
      conn
    else
      conn
      |> send_resp(:bad_request, "")
      |> halt()
    end
  end
end
