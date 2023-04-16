defmodule Shin.Utils do

  @moduledoc false

  alias Shin.IdP

  @spec named_version() :: binary()
  def named_version do
    "Shin #{Application.spec(:shin, :vsn)}"
  end

  @spec wrap_results(results :: tuple()) :: any()
  def wrap_results(results) do
    case results do
      {:ok, data} -> data
      {:error, msg} -> raise msg
    end
  end

  @spec build_attribute_query(idp :: IdP.t(), sp :: binary(), username :: binary(), options :: keyword()) :: keyword()
  def build_attribute_query(idp, sp, username, options) do
    query = [requester: sp, principal: username]
    query = if is_nil(options[:acs_index]), do: query, else: Keyword.merge(query, [acsIndex: "#{options[:acs_index]}"])
  end

  @spec build_mdq_query(idp :: binary | IdP.t(), entity_id :: binary(), options :: keyword() ) :: keyword()
  def build_mdq_query(idp, entity_id, options) do
    query = [entityID: entity_id]
    query = if is_nil(options[:protocol]), do: query, else: Keyword.merge(query, [protocol: "#{options[:protocol]}"])
  end

  @spec build_mdr_query(idp :: binary | IdP.t(), mdp_id :: binary(), options :: keyword()) :: keyword()
  def build_mdr_query(idp, mdp_id, options) do
    query = [id: mdp_id]
  end

  @spec build_lockout_path(idp :: binary | IdP.t(), username :: binary(), ip_address :: binary, options :: keyword()) :: binary()
  def build_lockout_path(idp, username, ip_address, options) do
    [idp.lockout_path, idp.lockout_bean, "#{username}!#{ip_address}"]
    |> Enum.join("/")
  end

  @spec build_service_reload_query(idp :: binary | IdP.t(), service :: atom() | binary(), options :: keyword()) :: keyword()
  def build_service_reload_query(idp, service, options) do
    query = [id: service]
  end

  @spec guess_service_metric_id(service :: binary) :: binary()
  def guess_service_metric_id(service) do
    service
    |> String.replace_leading("shibboleth.", "")
    |> String.replace("Service", "")
    |> String.replace("Reloadable", "")
    |> Macro.underscore()
    |> String.replace("_", ".")
  end

  ####################################################################################################

end
