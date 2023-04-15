defmodule Shin.Assertion do

  @moduledoc false

  alias Shin.HTTP
  alias Shin.Utils

  def query(idp, _sp, _username, options \\ [])
  def query(idp, _, _, _) when is_binary(idp) do
    {:error, "IdP record is required"}
  end

  def query(idp, sp, username, options) do
    query_params = Keyword.merge(Utils.build_attribute_query(idp, sp, username, options), [saml2: true])
    options = Keyword.merge(options, [type: :saml2])
    HTTP.get_data(idp, idp.attributes_path, query_params, options)
  end

  def query!(idp, sp, username, options \\ [])
  def query!(idp, _, _, _) when is_binary(idp) do
    raise "IdP record is required"
  end

  def query!(idp, sp, username, options) do
    Utils.wrap_results(query(idp, sp, username, options))
  end

  ####################################################################################################


end
