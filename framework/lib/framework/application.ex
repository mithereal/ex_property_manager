defmodule Framework.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  alias Framework.Application.Setup

  @impl true
  def start(_type, _args) do
    oban_params = Application.fetch_env!(:framework, Oban) ++ [name: Framework.Oban]

    children = [
      FrameworkWeb.Telemetry,
      Framework.Repo,
      {DNSCluster, query: Application.get_env(:framework, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Framework.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Framework.Finch},
      {Oban, oban_params},
      # Start a worker by calling: Framework.Worker.start_link(arg)
      # {Framework.Worker, arg},
      # Start to serve requests, typically the last entry
      {Registry, keys: :duplicate, name: ThemeRegistry},
      {Registry, keys: :unique, name: :user_registry},
      Framework.User.Server.Supervisor,
      FrameworkWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Framework.Supervisor]

    Supervisor.start_link(children, opts)
    |> Setup.main()
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    FrameworkWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  @version Mix.Project.config()[:version]
  @elixir Mix.Project.config()[:elixir]
  @description Mix.Project.config()[:description]

  def description, do: @description
  def version, do: [language: @elixir, application: @version]
end
