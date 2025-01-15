defmodule FrameworkWeb.RobotHTML do
  use FrameworkWeb, :html

  embed_templates "robot_html/*"

  def render("robots.txt", %{env: :prod}) do
    """
    User-agent: *
    Disallow: /admin
    """
  end

  def render("robots.txt", %{env: _}) do
    """
    User-agent: *
    Disallow: /
    """
  end
end
