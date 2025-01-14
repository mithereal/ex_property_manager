defmodule Framework.Application.Setup do
  require Logger

  def main(data) do
    data
    #    |> setup_default_users()
    #    |> load_settings()
    #    |> build_sitemap()
  end

  def build_sitemap(response) do
    state = %{id: "sitemap", schedule_in: 15}
    Framework.Workers.Sitemap.enqueue(state, :start)
    response
  end

  def setup_default_users(response) do
    state = %{
      id: "default_users",
      name: "admin",
      email: "admin@localhost.com",
      password: "123456789",
      schedule_in: 15
    }

    Framework.Workers.Setup.Users.enqueue(state, :start)
    response
  end

  def load_settings(response) do
    state = %{id: "settings", schedule_in: 15}
    Framework.Workers.Settings.enqueue(state, :start)
    response
  end
end
