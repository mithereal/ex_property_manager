defmodule FrameworkWeb.FileController do
  @moduledoc """
  Serves files based on short-term token grants.
  """
  use FrameworkWeb, :controller

  alias Framework.MediaLibrary

  require Logger

  def show(conn, %{"id" => filename_uuid, "token" => token}) do
    case Phoenix.Token.decrypt(conn, "file", token, max_age: :timer.minutes(1)) do
      {:ok, %{vsn: 1, uuid: ^filename_uuid, size: _size}} ->
        path = MediaLibrary.local_filepath(filename_uuid)
        do_send_file(conn, path)

      _ ->
        send_resp(conn, :unauthorized, "")
    end
  end

  defp do_send_file(conn, path) do
    # accept-ranges headers required for chrome to seek via currentTime
    conn
    |> put_resp_header("content-type", MIME.from_path(path))
    |> put_resp_header("accept-ranges", "bytes")
    |> send_file(200, path)
  end

  defp proxy_file(conn, ip, mime_type, content_length) do
    uri = conn |> request_url() |> URI.parse()
    port = FrameworkWeb.Endpoint.config(:http)[:port]
    path = uri.path <> "?" <> uri.query <> "&from=#{server_ip()}"
    {:ok, ipv6} = :inet.parse_address(String.to_charlist(ip))
    {:ok, req} = Mint.HTTP.connect(:http, ipv6, port, file_server_opts())
    {:ok, req, request_ref} = Mint.HTTP.request(req, "GET", path, [], "")

    conn
    |> put_resp_header("content-type", mime_type)
    |> put_resp_header("accept-ranges", "bytes")
    |> put_resp_header("content-length", to_string(content_length))
    |> send_chunked(200)
    |> stream(req, request_ref)
  end

  defp stream(conn, req, ref) do
    receive do
      {:tcp, _, _} = msg ->
        {:ok, req, responses} = Mint.HTTP.stream(req, msg)

        new_conn =
          Enum.reduce(responses, conn, fn
            {:data, ^ref, data}, acc -> chunk!(acc, data)
            {:done, ^ref}, acc -> halt(acc)
            {:status, ^ref, 200}, acc -> acc
            {:headers, ^ref, _}, acc -> acc
          end)

        if new_conn.halted do
          new_conn
        else
          stream(new_conn, req, ref)
        end
    end
  end

  defp chunk!(conn, data) do
    {:ok, conn} = chunk(conn, data)
    conn
  end

  defp local_file?(_filename_uuid, ip) do
    # TODO cache locally
    ip == server_ip()
  end

  defp server_ip, do: Framework.config([:files, :server_ip])

  defp file_server_opts do
    [
      hostname: Framework.config([:files, :hostname]) || "localhost",
      transport_opts: Framework.config([:files, :transport_opts]) || []
    ]
  end
end
