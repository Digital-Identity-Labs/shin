defmodule Shin.Assertion do

  @moduledoc """
  Queries a Shibboleth IdP for simulated attribute assertions - producing XML that should be
    similar to the SAML sent to an SP, containing the same user information.

  The SAML assertion XML is not validated or parsed in any way. It should accurately reflect the assertion and attributes released
  by the IdP.

  If your IdP is using another IdP as a proxy then any attributes derived from the upstream IdP will be missing: only
    attributes sourced or created by the Shibboleth IdP can be returned.

  """

  alias Shin.IdP
  alias Shin.HTTP
  alias Shin.Utils

  @doc """
  Looks up attributes likely to be released to the specified SP for the specified user, returning them as an XML text
  in a result tuple.

  Pass the IdP, followed by the SP's entity ID and the username/principal of the user.

  ## Examples

    ```
    {:ok, assertion_xml} = Shin.Assertion.query(idp, "https://test.ukfederation.org.uk/entity", "pete")
    ```

  """
  @spec query(idp :: IdP.t(), sp :: binary(), username :: binary(), options :: keyword()) :: {:ok, binary()} | {
    :error,
    binary()
  }
  def query(idp, sp, username, options \\ [])
  def query(idp, _, _, _) when is_binary(idp) do
    {:error, "IdP record is required"}
  end

  def query(idp, sp, username, options) do
    query_params = Keyword.merge(Utils.build_attribute_query(idp, sp, username, options), [saml2: true])
    options = Keyword.merge(options, [type: :saml2])
    HTTP.get_data(idp, idp.attributes_path, query_params, options)
  end

  @doc """
  Looks up attributes likely to be released to the specified SP for the specified user, returning XML as a binary string.

  Pass the IdP, followed by the SP's entity ID and the username/principal of the user.

  ## Examples

    ```
    assertion_xml = Shin.Assertion.query!(idp, "https://test.ukfederation.org.uk/entity", "pete")
    ```

  """
  @spec query!(idp :: IdP.t(), sp :: binary(), username :: binary(), options :: keyword()) :: binary()
  def query!(idp, sp, username, options \\ [])
  def query!(idp, _, _, _) when is_binary(idp) do
    raise "IdP record is required"
  end

  def query!(idp, sp, username, options) do
    Utils.wrap_results(query(idp, sp, username, options))
  end

  ####################################################################################################

end
