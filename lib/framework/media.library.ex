defmodule Framework.MediaLibrary do
  @moduledoc """
  The MediaLibrary context.
  """

  require Logger
  import Ecto.Query, warn: false
  alias Framework.Images.Image

  def store_image(%Image{} = image, tmp_path) do
    File.mkdir_p!(Path.dirname(image.filepath))
    {:ok, _} = File.copy(tmp_path, image.filepath)
  end

  defp delete_image_file(image) do
    case File.rm(image.filepath) do
      :ok ->
        :ok

      {:error, reason} ->
        Logger.info(
          "unable to delete image #{image.id} at #{image.filepath}, got: #{inspect(reason)}"
        )
    end
  end
end
