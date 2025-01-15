defmodule FrameworkWeb.RobotController do
  use FrameworkWeb, :controller

  alias FrameworkWeb

  @sizes [
    [size: "36x36", density: "0.75"],
    [size: "48x48", density: "1.0"],
    [size: "72x72", density: "1.5"],
    [size: "144x144", density: "2.0"],
    [size: "192x192", density: "3.0"]
  ]

  def robots(conn, _params) do
    conn
    |> put_resp_content_type("text/plain")
    |> render("robots.txt", %{env: Application.get_env(:framework, :app_env)})
  end

  def site_webmanifest(conn, _params) do
    json(conn, %{
      name: FrameworkWeb.Endpoint.host(),
      short_name: FrameworkWeb.Endpoint.host(),
      icons:
        for [size: size, density: density] <- @sizes do
          %{
            src: ~p"/images/" <> "android-chrome-#{size}.png",
            sizes: size,
            density: density,
            type: "image/png"
          }
        end,
      theme_color: "#663399",
      display: "minimal-ui",
      background_color: "#ffffff"
    })
  end

  def browserconfig(conn, _params) do
    conn
    |> put_resp_content_type("text/xml")
    |> render("browserconfig.xml", %{conn: conn})
  end

  def sitemap(conn, _params) do
    data = File.read("sitemap.xml")

    conn
    |> put_resp_content_type("text/xml")
    |> render("sitemap.xml", data: data)
  end

  def pwa(conn, _params) do
    meta_attrs = [
      %{name: "og:title", content: "Websockets PWA"},
      %{name: "og:image", content: "/images/websockets_512.png"},
      %{name: "og:description", content: "Client PWA"},
      %{name: "description", content: "Websockets Client PWA"}
    ]

    page_title = "Application"
    manifest = "/pwa.json"

    render(conn, :pwa,
      layout: false,
      meta_attrs: meta_attrs,
      page_title: page_title,
      manifest: manifest
    )
  end
end
