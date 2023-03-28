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
    query = if is_nil(options[:acs_index]), do: query, else: Keyword.merge(query, [acsIndex: options[:acs_index]])
  end

  def build_mdq_query(idp, entity_id, options) do
    query = [entityID: entity_id]
    query = if is_nil(options[:protocol]), do: query, else: Keyword.merge(query, [protocol: options[:protocol]])
  end

  def build_mdr_query(idp, mdp_id, options) do
    query = [id: mdp_id]
  end

  ####################################################################################################


end
