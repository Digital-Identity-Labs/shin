defmodule Shin.Attributes do

  @moduledoc """
  XXX
  """

  alias Shin.HTTP
  alias Shin.Utils
  alias Shin.IdP

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

  @spec query!(idp :: IdP.t(), sp :: binary(), username :: binary(), options :: keyword()) :: map()
  def query!(idp, sp, username, options \\ [])
  def query!(idp, _, _, _) when is_binary(idp) do
    raise "IdP record is required"
  end

  def query!(idp, sp, username, options) do
    Utils.wrap_results(query(idp, sp, username, options))
  end

  @spec principal(results :: map()) :: binary()
  def principal(%{"principal" => principal}) do
    principal
  end

  @spec username(results :: map()) :: binary()
  def username(results) do
    principal(results)
  end

  @spec requester(results :: map()) :: binary()
  def requester(%{"requester" => requester}) do
    requester
  end

  @spec sp(results :: map()) :: binary()
  def sp(results) do
    requester(results)
  end

  @spec attributes(results :: map()) :: map()
  def attributes(%{"attributes" => attributes}) do
    attributes
    |> Enum.map(fn a -> {a["name"], a["values"]} end)
    |> Map.new()
  end

  @spec names(results :: map()) :: list()
  def names(results) do
    attributes(results)
    |> Map.keys()
  end

  @spec values(results :: map(), attribute_name :: binary()) :: list()
  def values(results, attribute_name) do
    (attributes(results)
    |> Enum.map(fn {k,v} -> {String.downcase(k), v} end)
    |> Map.new()
    |> Map.get(String.downcase(attribute_name))) || []
  end

  ####################################################################################################

end
