defmodule FrameworkWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :framework

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.
  @session_options [
    store: :cookie,
    key: "_framework_key",
    signing_salt: "l2n+cuFy",
    same_site: "Lax"
  ]

  socket "/live", Phoenix.LiveView.Socket,
    websocket: [connect_info: [session: @session_options]],
    longpoll: [connect_info: [session: @session_options]]

  plug :health
  plug :router_url

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phx.digest
  # when deploying your static files in production.
  plug Plug.Static,
    at: "/",
    from: :framework,
    gzip: false,
    only: FrameworkWeb.static_paths()

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
    plug Phoenix.LiveReloader
    plug Phoenix.CodeReloader
    plug Phoenix.Ecto.CheckRepoStatus, otp_app: :framework
  end

  plug Phoenix.LiveDashboard.RequestLogger,
    param_key: "request_logger",
    cookie_key: "request_logger"

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Session, @session_options
  plug FrameworkWeb.Router

  def health(conn, _) do
    case conn do
      %{request_path: "/health"} -> conn |> send_resp(200, "OK") |> halt()
      _ -> conn
    end
  end

  def router_url(conn, _) do
    uri = %URI{struct_url() | host: conn.host, scheme: "#{conn.scheme}", port: conn.port}

    conn
    |> Phoenix.Controller.put_router_url(uri)
    |> Phoenix.Controller.put_static_url(uri)
  end

  def static_headers(conn) do
    case conn.request_path do
      "/assets/serviceworker.js" -> [{"Service-Worker-Allowed", "/"}]
      _ -> []
    end
  end
end
