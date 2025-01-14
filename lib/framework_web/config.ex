defmodule FrameworkWeb.Config do
  def endpoint_store(default \\ :cookie) do
    Application.get_env(:framework, :endpoint_store, default)
  end

  def endpoint_key(default \\ "_web_key") do
    Application.get_env(:framework, :endpoint_key, default)
  end

  def endpoint_signing_salt(default \\ "gTm6MBR2") do
    Application.get_env(:framework, :endpoint_signing_salt, default)
  end

  def endpoint_same_site(default \\ "Lax") do
    Application.get_env(:framework, :endpoint_same_site, default)
  end

  def ssl_domains(default \\ [{"example.com", "demo@example.com"}]) do
    Application.get_env(:framework, :ssl_endpoint_domain_info, default)
  end

  def ssl_port(default \\ 4002) do
    Application.get_env(:framework, :ssl_endpoint_port, default)
  end

  def site_author(default \\ "mithereal") do
    Application.get_env(:framework, :site_author, default)
  end

  def site_default_title(default \\ "") do
    Application.get_env(:framework, :site_default_title, default)
  end

  def site_default_suffix(default \\ "") do
    Application.get_env(:framework, :site_default_suffix, default)
  end

  def site_default_description(default \\ "") do
    Application.get_env(:framework, :site_default_description, default)
  end

  def site_default_theme_color(default \\ "#663399") do
    Application.get_env(:framework, :site_default_theme_color, default)
  end

  def site_themes_list(default \\ ["default"]) do
    Application.get_env(:framework, :site_themes_list, default)
  end

  def site_default_windows_tile_color(default \\ "#663399") do
    Application.get_env(:framework, :site_default_windows_tile_color, default)
  end

  def site_default_mask_icon_color(default \\ "#663399") do
    Application.get_env(:framework, :site_default_mask_icon_color, default)
  end

  def site_default_locale(default \\ "en_US") do
    Application.get_env(:framework, :site_default_locale, default)
  end

  def google_site_verification(default \\ "") do
    Application.get_env(:framework, :google_site_verification, default)
  end

  def site_title_prefix(default \\ "") do
    Application.get_env(:framework, :site_title_prefix, default)
  end
end
