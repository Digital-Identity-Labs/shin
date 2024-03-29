defmodule Shin.HTTP do

  @moduledoc false

  alias Shin.IdP
  alias Shin.Utils

  @spec get_data(idp :: IdP.t(), path :: binary, options :: keyword()) :: {:ok, map() | binary()} | {:error, binary}
  def get_data(idp, path, params \\ [], options \\ []) do

    results = Req.get(client(idp, options), url: path, params: params)

    case results do
      {:ok, result} -> if Enum.member?(200..299, result.status) do
                         {:ok, tidy_data(result.body)}
                       else
                         {:error, "Error #{result.status}"}
                       end
      {:error, msg} -> {:error, msg}
    end

  end

  @spec post_data(idp :: IdP.t(), path :: binary, options :: keyword()) :: {:ok, map() | binary()} | {:error, binary}
  def post_data(idp, path, params \\ [], options \\ []) do


    pclient = client(idp, options)
              |> Req.Request.put_new_header("content-type", "application/json")

    results = Req.post(pclient, url: path, params: params)


    case results do
      {:ok, result} -> if Enum.member?(200..299, result.status) do
                         {:ok, tidy_data(result.body)}
                       else
                         {:error, "Error #{result.status}"}
                       end
      {:error, msg} -> {:error, msg}
    end

  end

  @spec del_data(idp :: IdP.t(), path :: binary, options :: keyword()) :: {:ok, map() | binary()} | {:error, binary}
  def del_data(idp, path, params \\ [], options \\ []) do

    results = Req.delete(client(idp, options), url: path, params: params)

    case results do
      {:ok, result} -> if Enum.member?(200..299, result.status) do
                         {:ok, tidy_data(result.body)}
                       else
                         {:error, "Error #{result.status}"}
                       end
      {:error, msg} -> {:error, msg}
    end

  end

  ####################################################################################################

  @spec client(idp :: IdP.t(), options :: keyword()) :: struct()
  defp client(idp, options \\ [type: nil])
  defp client(idp, options) when is_struct(idp) do

    Req.new(
      base_url: idp.base_url,
      user_agent: http_agent_name(),
      headers: [{"accept", http_type(options[:type])}, {"Accept-Charset", "utf-8"}],
      connect_options: [
        timeout: idp.timeout
      ],
      max_retries: idp.retries
    )
  end

  defp client(_idp, _type) do
    raise "Shin.HTTP client requires a Shin.IdP struct as the first parameter!"
  end

  @spec tidy_data(data :: binary() | map()) :: binary() | map()
  defp tidy_data(data) when is_binary(data) do
    data
    |> String.trim()
  end

  defp tidy_data(data) when is_map(data) do
    data
  end

  @spec http_agent_name() :: binary()
  defp http_agent_name do
    Utils.named_version()
  end

  @spec http_type(type :: atom() | binary()) :: binary()
  defp http_type(type) when is_binary(type) do
    type
    |> String.to_existing_atom()
    |> http_type()
  end

  defp http_type(type) do
    case type do
      nil -> "*/*"
      :saml2 -> "application/samlassertion+xml"
      :saml_md -> "application/samlmetadata+xml"
      :json -> "application/json"
      :txt -> "text/plain"
      :text -> "text/plain"
    end
  end

end
