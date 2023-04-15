defmodule Shin.Metadata do

  @moduledoc """
  XXX
  """
  alias Shin.HTTP
  alias Shin.Utils
  alias Shin.Metrics

  def query(idp, entity_id, options \\ [])
  def query(idp, _, _) when is_binary(idp) do
    {:error, "IdP record is required"}
  end

  def query(idp, entity_id, options) do
    query_params = Utils.build_mdq_query(idp, entity_id, options)
    options = Keyword.merge(options, [type: :saml_md])
    HTTP.get_data(idp, idp.md_query_path, query_params, options)
  end

  def query!(idp, sentity_id, options \\ [])
  def query!(idp, _, _) when is_binary(idp) do
    raise "IdP record is required"
  end

  def query!(idp, entity_id, options) do
    Utils.wrap_results(query(idp, entity_id, options))
  end

  def providers(idp) do
    case Shin.metrics(idp) do
      {:ok, metrics} ->
        metrics
        |> Map.get("timers")
        |> Map.keys()
        |> Enum.map(fn key_text -> extract_provider_from_timer(key_text) end)
        |> Enum.reject(fn v -> is_nil(v) end)
        |> Enum.uniq()
        |> Enum.sort()
      {:error, _} -> []
    end

  end

  def reload(idp, mdp_id, options \\ []) do
    query_params = Utils.build_mdr_query(idp, mdp_id, options)
    options = Keyword.merge(options, [type: :text])
    HTTP.get_data(idp, idp.md_reload_path, query_params, options)
  end

  def cache(idp, entity_ids) do
    entity_ids
    |> List.wrap()
    |> Enum.map(
         fn entity_id -> try do
                           case query(idp, entity_id) do
                             {:ok, _} -> entity_id
                             {:error, _} -> nil
                           end
                         rescue
                           _ -> nil
                         end
         end
       )
    |> Enum.reject(fn v -> is_nil(v) end)
  end

  def protocols() do
    [:cas, :saml1, :saml2]
  end

  ####################################################################################################

  defp extract_provider_from_timer("org.opensaml.saml.metadata.resolver.impl" <> text) do
    text
    |> String.split(".")
    |> Enum.at(2)
  end

  defp extract_provider_from_timer(_) do
    nil
  end

end
