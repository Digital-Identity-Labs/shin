defmodule Shin.Service do

  @moduledoc false

  alias Shin.IdP
  alias Shin.HTTP
  alias Shin.Utils

  def query(idp, sp, username, options \\ []) do
    query_params = Keyword.merge(Utils.build_attribute_query(idp, sp, username, options), [saml2: true])
    options = Keyword.merge(options, [type: :saml2])
    HTTP.get_data(idp, idp.attributes_path, query_params, options)
  end

  def query!(idp, sp, username, options \\ []) do
    Utils.wrap_results(query(idp, sp, username, options))
  end

  @spec reload(idp :: IdP.t(), service :: atom | binary) ::
          {:ok, binary} | {:error, binary}
  def reload(idp, service, options \\ []) do
    with {:ok, service} <- IdP.validate_service(idp, service) do
      options = Keyword.merge(options, [type: :text])
      query_params = Utils.build_service_reload_query(idp, service, options)
      HTTP.get_data(idp, idp.reload_path, query_params, options)
    else
      err -> err
    end
  end

  @spec reload!(idp :: IdP.t(), service :: atom | binary) :: binary
  def reload!(idp, service, options \\ []) do
    options = Keyword.merge(options, [type: :text])
    query_params = Utils.build_service_reload_query(idp, service, options)
    case reload(idp, service, options) do
      {:ok, message} -> if String.contains?(message, "Configuration reloaded for") do
                          message
                        else
                          raise "Could not reload service #{service}!"
                        end
      {:error, message} -> raise "Could not reload service #{service}: #{message}!"
    end
  end

  ####################################################################################################


end
