defmodule Shin do

  @moduledoc """
  `Shin` is a simple Elixir client for the [Shibboleth IdP's](https://www.shibboleth.net/products/) admin features.
  Currently it can collect metrics and trigger service reloads.

  Shin can be used to gather information about your IdP servers such as Java version and IdP version, and can also collect any
  other information defined as a metric within the IdP. Shin can return the raw data or reformat it into simpler reports.

  The Shibboleth IdP will automatically reload valid configuration files but may stop retrying if passed an incorrect file.
  Shin can be used to prompt the IdP to immediately reload parts of its configuration.

  ## Overview

  The `Shin` module contains a few useful functions that are probably enough for most tasks. The `Shin.Metrics` and
  `Shin.Reports` modules provide extra functions for handling the returned metrics.

  ### Defining an IdP target

  To define an IdP using a default configuration you only need the base URL of the IdP service

      iex> Shin.idp("https://example.com/idp")
      {:ok, %Shin.IdP{
        base_url: "https://example.com/idp",
        metric_groups: [:core, :idp, :logging, :access, :metadata, :nameid,
          :relyingparty, :registry, :resolver, :filter, :cas, :bean],
        metrics_path: "profile/admin/metrics",
        no_dns_check: false,
        reload_path: "profile/admin/reload-service",
        reloadable_services: %{
          access_control: "shibboleth.ReloadableAccessControlService",
          attribute_filter: "shibboleth.AttributeFilterService",
          attribute_registry: "shibboleth.AttributeRegistryService",
          attribute_resolver: "shibboleth.AttributeResolverService",
          cas_registry: "shibboleth.ReloadableCASServiceRegistry",
          managed_beans: "shibboleth.ManagedBeanService",
          metadata_resolver: "shibboleth.MetadataResolverService",
          nameid_generator: "shibboleth.NameIdentifierGenerationService",
          relying_party_resolver: "shibboleth.RelyingPartyResolverService",
          logging: "shibboleth.LoggingService"
          },
        timeout: 2000
      }}

  If your IdP has different paths, metrics groups or reloadable services you can specify them as options.

  Functions in the top-level Shin module can also be passed a base URL if no configuration is needed.

  ### Downloading raw metrics

  ```
  {:ok, metrics} = Shin.metrics(idp)
  {:ok, metrics} = Shin.metrics(idp, :core)
  list_of_gauges = Shin.Metrics.gauge_ids(metrics)
  hostname = Shin.Metrics.gauge(metrics, "host.name")
  ```

  ### Producing a simplified report

  ```
  {:ok, report} = Shin.report(idp, :system_info)
  report.cores
  # => 4
  ```

  ### Triggering a service reload

  ```
  {:ok, message} = Shin.reload_service(idp, "shibboleth.AttributeFilterService")
  {:ok, message} = Shin.reload_service(idp, :attribute_filter)
  ```

  """

  alias Shin.IdP
  alias Shin.HTTP
  alias Shin.Reports

  @doc """
  Returns a structure representing an IdP and its configuration.

  Pass a URL as the first (and required) parameter. URL validation can be skipped by specifying ```no_dns_check: true``` as an
  option. Other options will replace defaults for the IdP's configuration.

  The URL is the base URL *of the IdP service*, not its entity ID. Normally this will include the "/idp" path.

  If you are not customising the configuration of the IdP at all you can skip creating an IdP struct and just pass the URL
  directly to the functions in this module. However, the other Shin modules *require* the full IdP struct.

  ## Examples

    ```
    {:ok, idp} = Shin.idp("https://example.com/idp")
    {:ok, idp} = Shin.idp("https://hostnamedoesnotexist.com/idp", no_dns_check: true)
    {:ok, idp} = Shin.idp("https://example.com/idp", metric_groups: [:core, :idp, :logging, :metadata, :errors])
    ```

  """
  @spec idp(idp :: binary | IdP.t(), opts :: keyword) :: {:ok, IdP.t()} | {:error, binary}
  def idp(idp, opts \\ []) do
    IdP.configure(idp, opts)
  end

  @doc """
  Sends a reload request for the specified service to the IdP. This should cause the IdP to reload the configuration
  for that service.

  Pass an IdP as the first parameter. The second parameter is either a full service ID or an alias provided by Shin.

  ## Examples

    ```
    {:ok, message} = Shin.reload_service(idp, "shibboleth.MetadataResolverService")
    {:ok, message} = Shin.reload_service("https://example.com/idp", :metadata_resolver)
    ```
  """
  @spec reload_service(idp :: binary | IdP.t(), service :: atom | binary) :: {:ok, binary} | {:error, binary}
  def reload_service(idp, service) do
    with {:ok, idp} <- prep_idp(idp),
         {:ok, service} <- IdP.validate_service(idp, service) do
      HTTP.get_reload(idp, service)
    else
      err -> err
    end
  end

  @doc """
  Returns default (all) raw metrics from the IdP as a map.

  Pass an IdP as the only parameter.

  ## Examples

    ```
    {:ok, metrics} = Shin.metrics(idp)
    ```

  """
  @spec metrics(idp :: binary | IdP.t()) :: {:ok, map()} | {:error, binary}
  def metrics(idp) do
    with {:ok, idp} <- prep_idp(idp) do
      HTTP.get_json(idp, idp.metrics_path)
    else
      err -> err
    end
  end

  @doc """
  Returns the specified raw metrics group from the IdP as a map.

  Pass an IdP struct or URL binary as the first parameter and the name of the group as the second (as atom or binary)

  ## Examples

    ```
    {:ok, metrics} = Shin.metrics(idp, :core)
    ```

  """
  @spec metrics(idp :: binary | IdP.t(), group :: atom | binary) :: {:ok, map()} | {:error, binary}
  def metrics(idp, group) do
    with {:ok, idp} <- prep_idp(idp),
         {:ok, group} <- IdP.validate_metric_group(idp, group),
         metrics_path <- IdP.metrics_path(idp, group) do
      HTTP.get_json(idp, metrics_path)
    else
      err -> err
    end
  end

  @doc """
  Returns reformated metrics as a simplified structure.

  The only parameter is the IdP struct or URL. The default report will be returned.

  ## Examples

    ```
    {:ok, report} = Shin.report(idp)
    ```

  """
  @spec report(idp :: binary | IdP.t()) :: {:ok, struct()} | {:error, binary}
  def report(idp) do
    report(idp, :system_info)
  end

  @doc """
  Returns metrics reformated using the specified module.

  The first parameter is the IdP struct or URL, the second is the alias or module name for the report processor.

  ## Examples

    ```
    {:ok, report} = Shin.report(idp, :system_info)
    {:ok, report} = Shin.report(idp, Shin.Reports.IdPInfo)
    ```

  """
  @spec report(idp :: binary | IdP.t(), reporter :: atom()) :: {:ok, struct()} | {:error, binary}
  def report(idp, reporter) do
    with {:ok, idp} <- prep_idp(idp),
         {:ok, metrics} <- metrics(idp) do
      Reports.produce(metrics, reporter)
    else
      err -> err
    end
  end

  @spec prep_idp(idp :: binary | IdP.t()) :: {:ok, struct()} | {:error, binary}
  defp prep_idp(idp) when is_binary(idp) do
    IdP.configure(idp)
  end

  defp prep_idp(%IdP{base_url: _} = idp) do
    {:ok, idp}
  end

end
