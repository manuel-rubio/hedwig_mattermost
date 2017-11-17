defmodule HedwigMattermost.HTTP do
  require Logger

  def login(url, username, password) do
    url = url <> "/api/v4/users/login"
    body = Poison.encode!(%{
      "login_id": username,
      "password": password
    })
    case HTTPoison.post(url, body, headers()) do
      {:ok, %{status_code: 200} = resp} ->
        token = :proplists.get_value("Token", resp.headers)
        {:ok, token}
      error ->
        Logger.info(fn () -> "login error: #{inspect(error)}" end)
        format_error(error)
    end
  end

  def create_post(url, token, post) do
    url = url <> "/api/v4/posts"
    body = Poison.encode!(post)
    case HTTPoison.post(url, body, headers(token)) do
      {:ok, %{status_code: 201}} -> :ok
      error ->
        Logger.info(fn () -> "create post error: #{inspect(error)}" end)
        format_error(error)
    end
  end

  defp format_error({:error, _} = error), do: error
  defp format_error({:ok, %HTTPoison.Response{} = resp}), do: {:error, resp}

  defp headers, do: %{"Content-type" => "application/json"}
  defp headers(token), do: %{"Content-type" => "application/json", "Authorization" => "Bearer #{token}"}
end
