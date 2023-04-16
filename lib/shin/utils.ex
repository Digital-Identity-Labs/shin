defmodule Shin.Utils do

  @moduledoc false

  alias Shin.IdP

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

  def build_attribute_query(idp, sp, username, options) do
    query = [requester: sp, principal: username]
    query = if is_nil(options[:acs_index]), do: query, else: Keyword.merge(query, [acsIndex: "#{options[:acs_index]}"])
  end

  def build_mdq_query(idp, entity_id, options) do
    query = [entityID: entity_id]
    query = if is_nil(options[:protocol]), do: query, else: Keyword.merge(query, [protocol: "#{options[:protocol]}"])
  end

  def build_mdr_query(idp, mdp_id, options) do
    query = [id: mdp_id]
  end

  # shibboleth.authn.Password.AccountLockoutManager/jdoe%21192.168.1.1
  def build_lockout_path(idp, username, ip_address, options) do
    [idp.lockout_path, idp.lockout_bean, "#{username}!#{ip_address}"]
    |> Enum.join("/")
  end

  def build_service_reload_query(idp, service, options) do
    query = [id: service]
  end

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
