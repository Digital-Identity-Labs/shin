defmodule Shin.Metadata do

  @moduledoc """
  Queries and reloads metadata at the IdP. Metadata for SAML entities can be downloaded and metadata providers can be reset.

  The module can be used to warm metadata caches, force reloads of metadata providers without restarting the IdP, and
    debug metadata source issues.
  """
  alias Shin.HTTP
  alias Shin.Utils
  alias Shin.Metrics
  alias Shin.IdP

  @doc """
  Query the IdP for metadata, returning the XML metadata for the specified entity ID if it can be found by the IdP.

  Metadata is looked up using the IdP's metadata providers, using each one in turn until metadata is found.

  The metadata XML is not parsed or validated in any way. If you need that sort of thing please take a look at the
    [Smee](https://hexdocs.pm/smee/readme.html) library.

  Pass the IdP and the entity ID of the SP.

  ## Examples

    ```
    {:ok, metadata_xml} = Shin.Metadata.query(idp, "https://test.ukfederation.org.uk/entity")
    ```

  """
  @spec query(idp :: IdP.t(), entity_id :: binary(), options :: keyword()) :: {:ok, binary()} | {:error, binary()}
  def query(idp, entity_id, options \\ [])
  def query(idp, _, _) when is_binary(idp) do
    {:error, "IdP record is required"}
  end

  def query(idp, entity_id, options) do
    query_params = Utils.build_mdq_query(idp, entity_id, options)
    options = Keyword.merge(options, [type: :saml_md])
    HTTP.get_data(idp, idp.md_query_path, query_params, options)
  end

  @doc """
  Query the IdP for metadata, returning the XML metadata for the specified entity ID if it can be found by the IdP.

  Metadata is looked up using the IdP's metadata providers, using each one in turn until metadata is found.

  The metadata XML is not parsed or validated in any way. If you need that sort of thing please take a look at the
    [Smee](https://hexdocs.pm/smee/readme.html) library.

  Pass the IdP and the entity ID of the SP.

  ## Examples

    ```
    metadata_xml = Shin.Metadata.query!(idp, "https://test.ukfederation.org.uk/entity")
    ```

  """
  @spec query!(idp :: IdP.t(), entity_id :: binary(), options :: keyword()) :: binary()
  def query!(idp, sentity_id, options \\ [])
  def query!(idp, _, _) when is_binary(idp) do
    raise "IdP record is required"
  end

  def query!(idp, entity_id, options) do
    Utils.wrap_results(query(idp, entity_id, options))
  end

  @doc """
  Lists active/known metadata providers at the IdP.

  Each metadata provider is a source of entity metadata. Shin makes a metrics API query to find them.

  ## Examples

    ```
    providers = Shin.Metadata.providers(idp)
    ```

  """
  @spec providers(idp :: IdP.t()) :: list()
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

  @doc """
  Sends a reload request for the specified metadata provider to the IdP. This should cause the IdP to reset and reload
    the metadata associated with that provider.

  Pass an IdP as the first parameter. The second parameter must be the provider name. You can list active providers with
    `Metadata.providers/1`

  ## Examples

    ```
    {:ok, _} = Shin.Metadata.reload(idp, "ukFederationMDQ")
    ```

  """
  @spec reload(idp :: IdP.t(), mdp_id :: binary(), options :: keyword()) :: {:ok, binary()} | {:error, binary()}
  def reload(idp, mdp_id, options \\ []) do
    query_params = Utils.build_mdr_query(idp, mdp_id, options)
    options = Keyword.merge(options, [type: :text])
    case HTTP.get_data(idp, idp.md_reload_path, query_params, options) do
      {:ok, message} -> {:ok, message}
      {:error, message} -> {:error, "Metadata reload failed for '#{mdp_id}'"}
    end
  end

  @doc """
  Similar to `query\3` but no metadata is returned - its purpose is to prime the IdP's cached metadata.

  The IDs of entities that were actually found and cached will be returned as a list.

  ## Examples

    ```
    ["https://test.ukfederation.org.uk/entity"] = Shin.Metadata.cache(idp, "https://test.ukfederation.org.uk/entity")
    ["https://test.ukfederation.org.uk/entity"] = Shin.Metadata.cache(idp, ["https://test.ukfederation.org.uk/entity", "http://example.com/fake"])
    ```

  """
  @spec cache(idp :: IdP.t(), entity_ids :: binary() | list()) :: list()
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

  @doc false
  @spec protocols() :: list()
  def protocols() do
    [:cas, :saml1, :saml2]
  end

  ####################################################################################################

  @spec extract_provider_from_timer(timer_id :: binary()) :: binary()
  defp extract_provider_from_timer("org.opensaml.saml.metadata.resolver.impl" <> text) do
    text
    |> String.split(".")
    |> Enum.at(2)
  end

  defp extract_provider_from_timer(_) do
    nil
  end

end
