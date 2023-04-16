defmodule Shin.Attributes do

  @moduledoc """
  Queries a Shibboleth IdP for attributes similar to the those sent to the specified SP for a user.

  Other functions in this module act as getters to retrieve information from the map.

  If your IdP is using another IdP as a proxy then any attributes derived from the upstream IdP will be missing: only
    attributes sourced or created by the Shibboleth IdP can be returned.
  """

  alias Shin.HTTP
  alias Shin.Utils
  alias Shin.IdP

  @doc """
  Looks up attributes likely to be released to the specified SP for the specified user, returning them as a map in a result
  tuple.

  ## Examples

    ```
    {:ok, query_results} = Shin.Attributes.query(idp, "https://test.ukfederation.org.uk/entity", "pete")
    ```

  """
  @spec query(idp :: IdP.t(), sp :: binary(), username :: binary(), options :: keyword()) :: {:ok, map()} | {
    :error,
    binary()
  }
  def query(idp, _sp, _username, options \\ [])
  def query(idp, _, _, _) when is_binary(idp) do
    {:error, "IdP record is required"}
  end

  def query(idp, sp, username, options) do
    query_params = Utils.build_attribute_query(idp, sp, username, options)
    options = Keyword.merge(options, [type: :json])
    HTTP.get_data(idp, idp.attributes_path, query_params, options)
  end

  @doc """
  Looks up attributes likely to be released to the specified SP for the specified user, returning them as a map.

  ## Examples

    ```
    query_results = Shin.Attributes.query!(idp, "https://test.ukfederation.org.uk/entity", "pete")
    ```

  """
  @spec query!(idp :: IdP.t(), sp :: binary(), username :: binary(), options :: keyword()) :: map()
  def query!(idp, sp, username, options \\ [])
  def query!(idp, _, _, _) when is_binary(idp) do
    raise "IdP record is required"
  end

  def query!(idp, sp, username, options) do
    Utils.wrap_results(query(idp, sp, username, options))
  end

  @doc """
  Returns the principal/username when passed attribute query results.

  (This is identical to `username/1`)

  ## Examples

    ```
    "pete" = Shin.Attributes.principal(query_results)
    ```

  """
  @spec principal(results :: map()) :: binary()
  def principal(%{"principal" => principal}) do
    principal
  end

  @doc """
  Returns the principal/username when passed attribute query results.

  (This is identical to `principal/1`)

  ## Examples

    ```
    "pete" = Shin.Attributes.username(query_results)
    ```

  """
  @spec username(results :: map()) :: binary()
  def username(results) do
    principal(results)
  end

  @doc """
  Returns the entityID of the SP that is supposedly "requesting" the attributes

  (This is the same as `sp/1`)

  ## Examples

    ```
        "https://test.ukfederation.org.uk/entity" = Shin.Attributes.requester(query_results)
    ```

  """
  @spec requester(results :: map()) :: binary()
  def requester(%{"requester" => requester}) do
    requester
  end

  @doc """
  Returns the entityID of the SP that is supposedly "requesting" the attributes

  (This is the same as `requester/1`)

  ## Examples

    ```
        "https://test.ukfederation.org.uk/entity" = Shin.Attributes.sp(query_results)
    ```

  """
  @spec sp(results :: map()) :: binary()
  def sp(results) do
    requester(results)
  end

  @doc """
  Returns a map of attribute friendly-names and values, taken from the attribute query results.

  (Friendly names are the LDAP-style, relatively human-friendly names of SAML attributes, rather than their URIs)

  ## Examples

    ```
      attributes = Shin.Attributes.attributes(query_results)
    ```

  """
  @spec attributes(results :: map()) :: map()
  def attributes(%{"attributes" => attributes}) do
    attributes
    |> Enum.map(fn a -> {a["name"], a["values"]} end)
    |> Map.new()
  end

  @doc """
  Returns a list of all attribute friendly-names in the query results.

  (Friendly names are the LDAP-style, relatively human-friendly names of SAML attributes, rather than their URIs)

  ## Examples

    ```
    {:ok, report} = Shin.Attributes.names(query_results)
    ```

  """
  @spec names(results :: map()) :: list()
  def names(results) do
    attributes(results)
    |> Map.keys()
  end

  @doc """
  Returns the values of the specified attribute in the query results.

  ## Examples

    ```
      ["urn:mace:dir:entitlement:common-lib-terms"] = Shin.Attributes.values(attr_data, "eduPersonEntitlement")
    ```

  """
  @spec values(results :: map(), attribute_name :: binary()) :: list()
  def values(results, attribute_name) do
    (attributes(results)
    |> Enum.map(fn {k,v} -> {String.downcase(k), v} end)
    |> Map.new()
    |> Map.get(String.downcase(attribute_name))) || []
  end

  ####################################################################################################

end
