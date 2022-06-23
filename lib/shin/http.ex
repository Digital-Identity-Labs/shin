defmodule Shin.HTTP do

  alias Shin.IdP

  def client(idp, type \\ :json) do

    middleware = essential_middleware(idp)
    middleware = case type do
      :json -> [Tesla.Middleware.JSON | middleware]
      _ -> middleware
    end

    Tesla.client(middleware)

  end

  def get_json(idp, path) do
    case Tesla.get(client(idp), path) do
      {:ok, result} -> {:ok, result.body}
      {:error, msg} -> {:error, msg}
    end
  end

  def get_reload(idp, service) do
    case Tesla.get(client(idp, :text), idp.reload_path, query: [id: service]) do
      {:ok, result} -> {:ok, String.trim(result.body)}
      {:error, msg} -> {:error, msg}
    end
  end

  defp essential_middleware(idp) do
    [
      {Tesla.Middleware.BaseUrl, idp.base_url},
      {Tesla.Middleware.Compression, format: "gzip"},
      {Tesla.Middleware.Timeout, timeout: idp.timeout}

    ]
  end

  defp json_middleware(idp) do
    [Tesla.Middleware.JSON]
  end

end