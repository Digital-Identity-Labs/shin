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

  ####################################################################################################


end
