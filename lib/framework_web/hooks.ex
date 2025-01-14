defmodule FrameworkWeb.Hooks do
  import Phoenix.Component
  import Phoenix.LiveView

  def on_mount(:current_path, _params, _session, socket) do
    socket =
      attach_hook(socket, :current_path_hook, :handle_params, fn _, uri, socket ->
        %{path: path} = URI.parse(uri)
        {:cont, assign(socket, current_path: path)}
      end)

    {:cont, socket}
  end
end
