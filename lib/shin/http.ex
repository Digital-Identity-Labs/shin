defmodule Shin.HTTP do

  alias Shin.IdP

  def get_json(idp, path) do
    case Tesla.get(client(idp, :json), path) do
      {:ok, result} -> if result.status == 200 do
                         {:ok, result.body}
                       else
                         {:error, "Error #{result.status}"}
                       end
      {:error, msg} -> {:error, msg}
    end
  end

  def get_reload(idp, service) do
    case Tesla.get(client(idp, :text), idp.reload_path, query: [id: service]) do
      {:ok, result} -> if result.status == 200 do
                          {:ok, String.trim(result.body)}
                       else
                          {:error, "Error #{result.status}"}
                       end
      {:error, msg} -> {:error, msg}
    end
  end

  defp client(%IdP{} = idp, type) when is_struct(idp) do

    middleware = essential_middleware(idp)
    middleware = case type do
      :json -> [Tesla.Middleware.JSON | middleware]
      :text -> middleware
      _ -> middleware
    end

    Tesla.client(middleware)

  end

  defp client(_idp, _type) do
    raise "Shin.HTTP client requires a Shin.IdP struct as the first parameter!"
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