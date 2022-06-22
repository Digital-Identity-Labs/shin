defmodule Shin.HTTP do


  def client(idp) do

    middleware = essential_middleware(idp)

    Tesla.client(middleware)

  end

  def metrics(idp) do
    get_json(idp, idp.metrics_path)
  end

  defp get_json(idp, path) do
    case Tesla.get(client(idp), path) do
      {:ok, result} -> {:ok, result.body}
      {:error, msg} -> {:error, msg}
    end
  end

  defp essential_middleware(idp) do
    [
      {Tesla.Middleware.BaseUrl, idp.base_url},
      Tesla.Middleware.JSON,
    ]
  end

end