defmodule Shin.Assertion do

  @moduledoc false

  alias Shin.HTTPX, as: HTTP
  alias Shin.Utils

  def query(idp, sp, username, options \\ []) do
    query_params = Keyword.merge(Utils.build_attribute_query(idp, sp, username, options), [saml2: true])
    options = Keyword.merge(options, [type: :saml2])
    HTTP.get_data(idp, idp.attributes_path, query_params, options)
  end

  def query!(idp, sp, username, options \\ []) do
    Utils.wrap_results(query(idp, sp, username, options))
  end

  ####################################################################################################


end
