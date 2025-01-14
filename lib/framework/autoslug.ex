defmodule Framework.AutoSlug do
  defmacro __using__(opts) do
    quote do
      def get_by_slug(slug) do
        Framework.Repo.get_by(__MODULE__, slug: slug)
      end

      def get_by_slug!(slug) do
        Framework.Repo.get_by!(__MODULE__, slug: slug)
      end
    end
  end

  def get_by_slug(slug, struct \\ %{}) do
    Framework.Repo.get_by(struct, slug: slug)
  end

  def get_by_slug!(slug, struct \\ %{}) do
    Framework.Repo.get_by!(struct, slug: slug)
  end
end
