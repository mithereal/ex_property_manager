defmodule Framework.Google do
  def authorize_url() do
    state = random_string()

    "https://google.com/login/oauth/authorize?client_id=#{client_id()}&state=#{state}&scope=user:email"
  end

  def exchange_access_token(opts) do
    code = Keyword.fetch!(opts, :code)
    state = Keyword.fetch!(opts, :state)

    state
    |> fetch_exchange_response(code)
    |> fetch_user_info()
    |> fetch_emails()
  end

  defp fetch_exchange_response(state, code) do
    resp =
      http(
        "google.com",
        "POST",
        "/login/oauth/access_token",
        [state: state, code: code, client_secret: secret()],
        [{"accept", "application/json"}]
      )

    with {:ok, resp} <- resp,
         %{"access_token" => token} <- Jason.decode!(resp) do
      {:ok, token}
    else
      {:error, _reason} = err -> err
      %{} = resp -> {:error, {:bad_response, resp}}
    end
  end

  defp fetch_user_info({:error, _reason} = error), do: error

  defp fetch_user_info({:ok, token}) do
    resp =
      http(
        "api.google.com",
        "GET",
        "/user",
        [],
        [{"accept", "application/vnd.google.v3+json"}, {"Authorization", "token #{token}"}]
      )

    case resp do
      {:ok, info} -> {:ok, %{info: Jason.decode!(info), token: token}}
      {:error, _reason} = err -> err
    end
  end

  defp fetch_emails({:error, _} = err), do: err

  defp fetch_emails({:ok, user}) do
    resp =
      http(
        "api.google.com",
        "GET",
        "/user/emails",
        [],
        [{"accept", "application/vnd.google.v3+json"}, {"Authorization", "token #{user.token}"}]
      )

    case resp do
      {:ok, info} ->
        emails = Jason.decode!(info)
        {:ok, Map.merge(user, %{primary_email: primary_email(emails), emails: emails})}

      {:error, _reason} = err ->
        err
    end
  end

  def random_string do
    binary = <<
      System.system_time(:nanosecond)::64,
      :erlang.phash2({node(), self()})::16,
      :erlang.unique_integer()::16
    >>

    binary
    |> Base.url_encode64()
    |> String.replace(["/", "+"], "-")
  end

  defp client_id, do: Framework.config([:google, :client_id])
  defp secret, do: Framework.config([:google, :client_secret])

  defp http(host, method, path, query, headers, body \\ "") do
    {:ok, conn} = Mint.HTTP.connect(:https, host, 443)

    path = path <> "?" <> URI.encode_query([{:client_id, client_id()} | query])

    {:ok, conn, ref} =
      Mint.HTTP.request(
        conn,
        method,
        path,
        headers,
        body
      )

    receive_resp(conn, ref, nil, nil, false)
  end

  defp receive_resp(conn, ref, status, data, done?) do
    receive do
      message ->
        {:ok, conn, responses} = Mint.HTTP.stream(conn, message)

        {new_status, new_data, done?} =
          Enum.reduce(responses, {status, data, done?}, fn
            {:status, ^ref, new_status}, {_old_status, data, done?} -> {new_status, data, done?}
            {:headers, ^ref, _headers}, acc -> acc
            {:data, ^ref, binary}, {status, nil, done?} -> {status, binary, done?}
            {:data, ^ref, binary}, {status, data, done?} -> {status, data <> binary, done?}
            {:done, ^ref}, {status, data, _done?} -> {status, data, true}
          end)

        cond do
          done? and new_status == 200 -> {:ok, new_data}
          done? -> {:error, {new_status, new_data}}
          !done? -> receive_resp(conn, ref, new_status, new_data, done?)
        end
    end
  end

  defp primary_email(emails) do
    Enum.find(emails, fn email -> email["primary"] end)["email"] || Enum.at(emails, 0)
  end
end