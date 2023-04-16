defmodule Shin.Service do

  alias Shin.IdP
  alias Shin.HTTP
  alias Shin.Metrics
  alias Shin.Utils

  @moduledoc """
  Queries and reloads sub-services at the IdP. Mostly it reloads subservices: things like logging, attribute filters, etc.
  """

  @doc """
  Looks up information about the specified Shibboleth IdP sub-service, returning it in a results tuple.

  At the moment the only useful information concerns when the service restarted (or failed to restart)

  The service can be specified using the full Shibboleth service ID or a Shin service alias. These are listed in your
    IdP struct.

  ## Examples

    ```
    {:ok, info} = Shin.Service.query(idp, "shibboleth.AttributeRegistryService")
    ```

  """
  @spec query(idp :: IdP.t(), service :: binary() | atom(), options :: keyword()) :: {:ok, map()} | {:error, binary()}
  def query(idp, service, options \\ [])
  def query(idp, _, _) when is_binary(idp) do
    {:error, "IdP record is required"}
  end

  def query(idp, service, options) do
    with {:ok, service} <- IdP.validate_service(idp, service),
         {:ok, metrics} <- Metrics.query(idp) do

      report = report_for_service(metrics, service)

      results = %{
        service: service,
        ok: ok?(report),
        reload_requested: reload_requested?(report),
        reload_attempted_at: report[:reload_attempt_at],
        reload_succeeded_at: report[:reload_success_at],
        reload_failed_at: report[:reload_error_at]
      }

      {:ok, results}

    else
      err -> err
    end

  end

  @doc """
  Looks up information about the specified Shibboleth IdP sub-service.

  At the moment the only useful information concerns when the service restarted (or failed to restart)

  The service can be specified using the full Shibboleth service ID or a Shin service alias. These are listed in your
    IdP struct.

  ## Examples

    ```
    info = Shin.Service.query!(idp, "shibboleth.AttributeRegistryService")
    ```

  """
  @spec query!(idp :: IdP.t(), service :: binary() | atom(), options :: keyword()) :: map()
  def query!(idp, service, options \\ []) do
    Utils.wrap_results(query(idp, service, options))
  end

  @doc """
  Sends a reload request for the specified service to the IdP. This should cause the IdP to reload the configuration
  for that service.

  Pass an IdP as the first parameter. The second parameter is either a full service ID or an alias provided by Shin.

  ## Examples

    ```
    {:ok, message} = Shin.Service.reload(idp, "shibboleth.MetadataResolverService")
    {:ok, message} = Shin.Service.reload(idp, :metadata_resolver)
    ```
  """
  @spec reload(idp :: IdP.t(), service :: atom | binary, options :: keyword()) ::
          {:ok, binary} | {:error, binary}
  def reload(idp, service, options \\ [])
  def reload(idp, _, _) when is_binary(idp) do
    {:error, "IdP record is required"}
  end

  def reload(idp, service, options) do
    with {:ok, service} <- IdP.validate_service(idp, service) do
      options = Keyword.merge(options, [type: :text])
      query_params = Utils.build_service_reload_query(idp, service, options)
      HTTP.get_data(idp, idp.reload_path, query_params, options)
    else
      err -> err
    end
  end

  @doc """
  Sends a reload request for the specified service to the IdP. This should cause the IdP to reload the configuration
  for that service.

  Pass an IdP as the first parameter. The second parameter is either a full service ID or an alias provided by Shin.

  ## Examples

    ```
    message = Shin.Service.reload!(idp, "shibboleth.MetadataResolverService")
    message = Shin.Service.reload!(idp, :metadata_resolver)
    ```
  """
  @spec reload!(idp :: IdP.t(), service :: atom | binary, options :: keyword()) :: binary
  def reload!(idp, service, options \\ [])
  def reload!(idp, _, _) when is_binary(idp) do
    raise "IdP record is required"
  end

  def reload!(idp, service, options) do
    options = Keyword.merge(options, [type: :text])
    query_params = Utils.build_service_reload_query(idp, service, options)
    case reload(idp, service, options) do
      {:ok, message} -> if String.contains?(message, "Configuration reloaded for") do
                          message
                        else
                          raise "Could not reload service #{service}!"
                        end
      {:error, message} -> raise "Could not reload service #{service}: #{message}!"
    end
  end

  ####################################################################################################

  @spec service_to_metric_id(service :: binary()) :: binary()
  defp service_to_metric_id(service) do
    case service do
      "shibboleth.RelyingPartyResolverService" -> "relyingparty"
      "shibboleth.MetadataResolverService" -> "metadata"
      "shibboleth.AttributeRegistryService" -> "attribute.registry"
      "shibboleth.AttributeResolverService" -> "attribute.resolver"
      "shibboleth.AttributeFilterService" -> "attribute.filter"
      "shibboleth.NameIdentifierGenerationService" -> "nameid"
      "shibboleth.ReloadableAccessControlService" -> "accesscontrol"
      "shibboleth.ReloadableCASServiceRegistry" -> "cas.registry"
      "shibboleth.ManagedBeanService" -> "managedbean"
      "shibboleth.LoggingService" -> "logging"
      _ -> Utils.guess_service_metric_id(service)
    end
  end

  @spec report_for_service(metrics :: map(), service :: binary()) :: map()
  defp report_for_service(metrics, service) do
    id = service_to_metric_id(service)
    mapper = %{
      reload_attempt_at: "net.shibboleth.idp.#{id}.reload.attempt",
      reload_success_at: "net.shibboleth.idp.#{id}.reload.success",
      reload_error_at: "net.shibboleth.idp.#{id}.reload.error",
    }

    Metrics.map_gauges(metrics, mapper)
    |> Enum.map(
         fn {k, v} -> if is_binary(v) do
                        {:ok, dv, _} = DateTime.from_iso8601(v)
                        {k, dv}
                      else
                        {k, v}
                      end
         end
       )
    |> Map.new()

  end

  @spec reload_requested?(report :: map()) :: boolean()
  defp reload_requested?(report) do
    !is_nil(report[:reload_attempt_at])
  end

  @spec ok?(report :: map()) :: boolean()
  defp ok?(report) do
    cond do
      is_nil(report[:reload_attempt_at]) -> true
      report[:reload_attempt_at] && is_nil(report[:reload_success_at]) -> false
      DateTime.compare(report[:reload_attempt_at], report[:reload_success_at]) == :eq -> true
    end
  end

end
