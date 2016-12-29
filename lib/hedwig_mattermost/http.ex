defmodule HedwigMattermost.HTTP do
  require Logger

  def login(url, username, password) do
    url = url <> "/api/v3/users/login"
    body = Poison.encode!(%{
      "login_id": username,
      "password": password
    })
    case HTTPoison.post(url, body, headers()) do
      {:ok, %{status_code: 200} = resp} ->
        token = :proplists.get_value("Token", resp.headers)
        {:ok, token}
      {:ok, resp} ->
        {:error, resp}
      error ->
        Logger.info("login error: #{inspect(error)}")
        error
    end
  end
end
