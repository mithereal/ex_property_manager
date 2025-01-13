defmodule FrameworkWeb.SEO do
  @moduledoc "You know, juice."
  use FrameworkWeb, :verified_routes
  alias FrameworkWeb.Config

  use SEO,
    site: &__MODULE__.site_config/1,
    open_graph: SEO.OpenGraph.build(locale: Config.site_default_locale()),
    twitter:
      SEO.Twitter.build(
        site: "@" <> Config.site_default_title(),
        creator: "@" <> Config.site_author()
      )

  def site_config(conn) do
    SEO.Site.build(
      title_prefix: Config.site_title_prefix(),
      title_suffix: Config.site_default_suffix(),
      default_title: Config.site_default_title(),
      description: Config.site_default_description(),
      theme_color: Config.site_default_theme_color(),
      windows_tile_color: Config.site_default_windows_tile_color(),
      mask_icon_color: Config.site_default_mask_icon_color(),
      mask_icon_url: static_url(conn, "/images/safari-pinned-tab.svg"),
      manifest_url: url(conn, ~p"/site.webmanifest"),
      google_site_verification: Config.google_site_verification()
    )
  end

  #
  #   defimpl SEO.OpenGraph.Audio.Build, for: Framework.Audio do
  #    use FrameworkWeb, :verified_routes
  #
  #    def build(params, conn) do
  #      SEO.OpenGraph.Audio.build(
  #        type: params.type,
  #        url: url(conn, ~p"/audio/#{params.slug}"),
  #        secure_url: url(conn, ~p"/audio/#{params.slug}")
  #      )
  #    end
  #    end
  #
  #   defimpl SEO.OpenGraph.Video.Build, for: Framework.Video do
  #    use FrameworkWeb, :verified_routes
  #
  #    def build(params, conn) do
  #      SEO.OpenGraph.Video.build(
  #        height: params.height,
  #        width: params.width,
  #        type: params.type,
  #        alt: params.alt,
  #        ya_allow_embed: params.ya_allow_embed,
  #        ya_bitrate: params.ya_bitrate,
  #        ya_quality: params.ya_quality,
  #        url: url(conn, ~p"/video/#{params.slug}"),
  #        secure_url: url(conn, ~p"/video/#{params.slug}")
  #      )
  #    end
  #    end

  ## defimpl SEO.OpenGraph.Build, for: Framework.Blog.Post do
  #  use FrameworkWeb, :verified_routes
  #
  #  def build(post, conn) do
  #    SEO.OpenGraph.build(
  #      title: SEO.Utils.truncate(post.title, 70),
  #      description: post.description,
  #      type: :article,
  #      type_detail:
  #        SEO.OpenGraph.Article.build(
  #          published_time: post.published && post.date,
  #          author: post.author,
  #          tag: post.tags
  #        ),
  #      url: url(conn, ~p"/blog/#{post.id}"),
  #      image: image(post, conn)
  #    )
  #  end

  #  defp image(post, conn) do
  #    file = "/images/post/#{post.id}.png"
  #
  #    exists? =
  #      [Application.app_dir(:framework), "/priv/static", file]
  #      |> Path.join()
  #      |> File.exists?()
  #
  #    if exists? do
  #      SEO.OpenGraph.Image.build(
  #        url: static_url(conn, file),
  #        alt: post.title
  #      )
  #    end
  #  end
  # end
  #
  ## defimpl SEO.Breadcrumb.Build, for: Framework.Blog.Post do
  #  use FrameworkWeb, :verified_routes
  #
  #  def build(post, conn) do
  #    SEO.Breadcrumb.List.build([
  #      %{name: "Posts", item: url(conn, ~p"/index")},
  #      %{name: post.title, item: url(conn, :show, ~p"/blog/#{post.id}")}
  #    ])
  #  end
  # end
  #
  ## defimpl SEO.Twitter.Build, for: Framework.Blog.Post do
  #  def build(_post, _conn) do
  #    SEO.Twitter.build(card: :summary_large_image)
  #  end
  # end
  #
  ## defimpl SEO.Site.Build, for: Framework.Blog.Post do
  #  def build(post, _conn) do
  #    SEO.Site.build(
  #      title: SEO.Utils.truncate(post.title, 70),
  #      description: post.description,
  #      canonical_url: post.canonical_url
  #    )
  #  end
  # end
  #
  ## defimpl SEO.Unfurl.Build, for: Framework.Blog.Post do
  #  def build(post, _conn) do
  #    if post.published do
  #      SEO.Unfurl.build(
  #        label1: "Reading Time",
  #        data1: format_time(post.reading_time),
  #        label2: "Published",
  #        data2: Date.to_iso8601(post.date)
  #      )
  #    end
  #  end

  #  defp format_time(length), do: "#{length} minutes"
  # end
end
