defmodule Shin.Attributes do

  @moduledoc """
  XXX
  """

  alias Shin.HTTP
  alias Shin.Utils

  def query(idp, _sp, _username, options \\ [])
  def query(idp, _, _, _) when is_binary(idp) do
    {:error, "IdP record is required"}
  end

  def query(idp, sp, username, options) do
    query_params = Utils.build_attribute_query(idp, sp, username, options)
    options = Keyword.merge(options, [type: :json])
    HTTP.get_data(idp, idp.attributes_path, query_params, options)
  end

  def query!(idp, sp, username, options \\ [])
  def query!(idp, _, _, _) when is_binary(idp) do
    raise "IdP record is required"
  end

  def query!(idp, sp, username, options) do
    Utils.wrap_results(query(idp, sp, username, options))
  end

  def principal(%{"principal" => principal}) do
    principal
  end

  def username(results) do
    principal(results)
  end

  def requester(%{"requester" => requester}) do
    requester
  end

  def sp(results) do
    requester(results)
  end

  def attributes(%{"attributes" => attributes}) do
    attributes
    |> Enum.map(fn a -> {a["name"], a["values"]} end)
    |> Map.new()
  end

  def names(results) do
    attributes(results)
    |> Map.keys()
  end

  def values(results, attribute_name) do
    (attributes(results)
    |> Enum.map(fn {k,v} -> {String.downcase(k), v} end)
    |> Map.new()
    |> Map.get(String.downcase(attribute_name))) || []
  end

  ####################################################################################################



end
