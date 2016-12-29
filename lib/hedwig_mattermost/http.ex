defmodule HedwigMattermost.HTTP do
  require Logger
  def login(url, username, password) do
    url = url <> "/api/v3/users/login"
    body = Poison.encode!(%{
      "login_id": username,
      "password": password
    })
    headers = %{"Content-type": "application/json"}
    case HTTPoison.post(url, body, headers) do
      {:ok, resp} ->
        case :proplists.get_value("Token", resp.headers) do
          :undefined ->
            Logger.info("login error: #{inspect(resp.body)}")
            {:error, :token_undefined}
          token -> {:ok, token}
        end
      error ->
        Logger.info("login error: #{inspect(error)}")
        error
    end
  end
end
