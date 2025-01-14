defmodule FrameworkWeb.Router do
  use FrameworkWeb, :router

  import FrameworkWeb.UserAuth

  alias FrameworkWeb, as: Web
  alias FrameworkWeb.Theme.Handler, as: ThemeHandler

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {FrameworkWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :webfinger do
    plug :accepts, ["jrd", "json"]
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :robots do
    plug :accepts, ~w[html json txt xml webmanifest]
  end

  scope "/", Web do
    pipe_through :browser

    get "/", PageController, :landing
  end

  scope "/", Web do
    pipe_through :webfinger

    get "/.well-known/webfinger", FingerController, :finger
  end

  scope "/oauth", Web do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    get "/callbacks/:provider", OAuthCallbackController, :new
  end

  scope "/aws", Web do
    pipe_through :api

    get "/", ApiController, :list_objects
    forward "/", ImagePlug, secret: &Framework.thumbor_secret/0
  end

  # Other scopes may use custom stacks.
  # scope "/api", FrameworkWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:framework, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: FrameworkWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
