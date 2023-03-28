defmodule Shin.Lockout do

  @moduledoc """
  XXX
  """

  alias Shin.HTTPX, as: HTTP
  alias Shin.Utils

  def query(idp, username, ip_address, options \\ []) do
    path = Utils.build_lockout_path(idp, username, ip_address, options)
    case HTTP.get_data(idp, path, [], options) do
      {:ok, data} -> Map.get(data, "data")
      {:error, msg} -> {:error, msg}
    end
  end

  def increment(idp, username, ip_address, options \\ []) do
    path = Utils.build_lockout_path(idp, username, ip_address, options)
    HTTP.post_data(idp, path, [], options)


  end

  def clear(idp, username, ip_address, options \\ []) do
    path = Utils.build_lockout_path(idp, username, ip_address, options)
    HTTP.del_data(idp, path, [], options)


  end

end
