defmodule FrameworkWeb do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, components, channels, and so on.

  This can be used in your application as:

      use FrameworkWeb, :controller
      use FrameworkWeb, :html

  The definitions below will be executed for every controller,
  component, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define additional modules and import
  those modules here.
  """

  def fetch_secret do
    Application.fetch_env!(:framework, __MODULE__)
    |> Keyword.fetch!(:secret_key)
  end

  def cdn do
    case Application.fetch_env!(:framework, __MODULE__) |> Keyword.get(:cdn) do
      nil -> "/image/"
      uri -> uri
    end
  end

  def favicons do
    ~w(android-chrome-192x192.png android-chrome-512x512.png apple-touch-icon.png favicon.ico icon.svg site.webmanifest)
  end

  def static_paths, do: ~w(assets fonts images svg favicon.ico robots.txt pwa.json)

  def router do
    quote do
      use Phoenix.Router, helpers: true

      # Import common connection and controller functions to use in pipelines
      import Plug.Conn
      import Phoenix.Controller
      import Phoenix.LiveView.Router
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
    end
  end

  def controller do
    quote do
      use Phoenix.Controller,
        formats: [:html, :json],
        layouts: [html: FrameworkWeb.Layouts]

      import Plug.Conn
      import FrameworkWeb.Gettext

      unquote(verified_routes())
    end
  end

  def live_view do
    quote do
      use Phoenix.LiveView,
        layout: {FrameworkWeb.Layouts, :app}

      unquote(html_helpers())
      unquote(live_view_helpers())
    end
  end

  def live_component do
    quote do
      use Phoenix.LiveComponent

      unquote(html_helpers())
    end
  end

  def html do
    quote do
      use Phoenix.Component

      # Import convenience functions from controllers
      import Phoenix.Controller,
        only: [get_csrf_token: 0, view_module: 1, view_template: 1]

      # Include general helpers for rendering HTML
      unquote(html_helpers())
    end
  end

  defp html_helpers do
    quote do
      # HTML escaping functionality
      import Phoenix.HTML
      # Core UI components and translation
      import FrameworkWeb.CoreComponents
      import FrameworkWeb.Gettext

      # Shortcut for generating JS commands
      alias Phoenix.LiveView.JS

      # Routes generation with the ~p sigil
      unquote(verified_routes())
    end
  end

  def verified_routes do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: FrameworkWeb.Endpoint,
        router: FrameworkWeb.Router,
        statics: FrameworkWeb.static_paths()
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/live_view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end

  defp live_view_helpers do
    quote do
      import FrameworkWeb.UserAuth, only: [signed_in_path: 1]

      @impl true
      def handle_info(%{event: "logout_user", payload: %{user: %{id: id}}}, socket) do
        with %{id: ^id} <- socket.assigns.current_user do
          {:noreply,
           socket
           |> redirect(to: url(~p"/force_logout"))}
        else
          _any -> {:noreply, socket}
        end
      end
    end
  end
end
