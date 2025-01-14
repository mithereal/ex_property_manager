defmodule FrameworkWeb.Theme.Handler do
  alias FrameworkWeb.Config

  def on_mount(:default, params, _session, socket) do
    theme = current_user_theme(socket, params)
    Registry.register(ThemeRegistry, :theme, theme)
    {:cont, socket}
  end

  def current_user_theme(socket, params = %{theme: "dark"}) do
    case Enum.member?(["current_user"], socket) do
      true ->
        socket.current_user.theme

      false ->
        params[:theme]
    end
  end

  # @before_compile {FrameworkWeb.Theme.Handler, :add_themes}

  def current_user_theme(socket, _params) do
    case Enum.member?(["current_user"], socket) do
      true ->
        socket.current_user.theme

      false ->
        "default"
    end
  end

  defmacro add_themes(_env) do
    quote do
      Config.site_themes_list()
      |> Enum.map(fn theme ->
        def current_user_theme(socket, params = %{theme: "#{theme}"}) do
          case Enum.member?(["current_user"], socket) do
            true ->
              socket.current_user.theme

            false ->
              params[:theme]
          end
        end
      end)
    end
  end
end
