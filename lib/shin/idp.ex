defmodule Shin.IdP do
  @moduledoc """
    This module contains the IdP structure used to configure requests to a particular IdP. The defaults should work
    for a typical fresh installation of Shibboleth IdP v4, but may require customisation if the IdP has a different
    path for endpoints, or additional metrics groups, etc.
  """

  alias __MODULE__
  require Logger

  @default_metric_groups [
    :core,
    :idp,
    :logging,
    :access,
    :metadata,
    :nameid,
    :relyingparty,
    :registry,
    :resolver,
    :filter,
    :cas,
    :bean,
  ]

  @default_reloadable_services %{
    relying_party_resolver: "shibboleth.RelyingPartyResolverService",
    metadata_resolver: "shibboleth.MetadataResolverService",
    attribute_registry: "shibboleth.AttributeRegistryService",
    attribute_resolver: "shibboleth.AttributeResolverService",
    attribute_filter: "shibboleth.AttributeFilterService",
    nameid_generator: "shibboleth.NameIdentifierGenerationService",
    access_control: "shibboleth.ReloadableAccessControlService",
    cas_registry: "shibboleth.ReloadableCASServiceRegistry",
    managed_beans: "shibboleth.ManagedBeanService",
    logging: "shibboleth.LoggingService"
  }

  @enforce_keys [:base_url]

  @type t :: %IdP{
               base_url: binary(),
               metrics_path: binary(),
               reload_path: binary(),
               attributes_path: binary(),
               md_query_path: binary(),
               md_reload_path: binary(),
               lockout_path: binary(),
               lockout_bean: binary(),
               metric_groups: list(),
               reloadable_services: map(),
               no_dns_check: boolean(),
               timeout: integer(),
               retries: integer()
             }

  defstruct [
    :base_url,
    metrics_path: "profile/admin/metrics",
    reload_path: "profile/admin/reload-service",
    attributes_path: "profile/admin/resolvertest",
    md_query_path: "profile/admin/mdquery",
    md_reload_path: "profile/admin/reload-metadata",
    lockout_path: "profile/admin/lockout",
    lockout_bean: "shibboleth.StorageBackedAccountLockoutManager",
    metric_groups: @default_metric_groups,
    reloadable_services: @default_reloadable_services,
    no_dns_check: false,
    timeout: 2_000,
    retries: 2
  ]

  @doc """
  Returns a structure representing an IdP and its configuration.

  Pass a URL as the only parameter (although it will pass-through existing IdP stucts too)

  The URL is the base URL *of the IdP service*, not its entity ID. Normally this will include the "/idp" path.

  ## Examples

  ```
  {:ok, idp} = Shin.IdP.configure("https://example.com/idp")
  {:ok, idp} = Shin.IdP.configure(idp) # pass-through an existing IdP struct
  ```

  """
  @spec configure(idp :: binary | IdP.t()) :: {:ok, IdP.t()} | {:error, binary}
  def configure(idp) when is_struct(idp) do
    {:ok, idp}
  end

  def configure(idp) when is_binary(idp) do
    configure(idp, [])
  end

  @doc """
  Returns a structure representing an IdP and its configuration.

  Pass a URL as the first (and required) parameter. URL validation can be skipped by specifying ```no_dns_check: true``` as an
  option. Other options will replace defaults for the IdP's configuration.

  The URL is the base URL *of the IdP service*, not its entity ID. Normally this will include the "/idp" path.

  ## Examples

  ```
  {:ok, idp} = Shin.IdP.configure("https://example.com/idp")
  {:ok, idp} = Shin.IdP.configure("https://hostnamedoesnotexist.com/idp", no_dns_check: true)
  {:ok, idp} = Shin.IdP.configure("https://example.com/idp", metric_groups: [:core, :idp, :logging, :metadata, :errors])
  ```

  """
  @spec configure(idp :: binary, options :: keyword()) :: {:ok, IdP.t()} | {:error, binary}
  def configure(base_url, options \\ []) when is_binary(base_url) and is_list(options) do
    with {:ok, url} <- validate_url(base_url, options),
         {:ok, opts} <- validate_opts(options) do
      {:ok, struct(IdP, merge(url, opts))}
    else
      err -> err
    end
  end

  @doc """
  Return a list of metric groups for the IdP, as atoms.

  ## Examples

  ```
  Shin.IdP.metric_groups(idp)
  # => [:core, :idp, :logging, :access, :metadata, :nameid, :relyingparty, :registry, :resolver, :filter, :cas, :bean]
  ```

  """
  @spec metric_groups(idp :: IdP.t()) :: list()
  def metric_groups(%IdP{metric_groups: values}) when is_nil(values) do
    []
  end

  def metric_groups(idp) do
    idp.metric_groups
  end

  @doc """
  Return a list of service IDs, as used by the Shibboleth IdP software.

  ## Examples

  ```
  Shin.IdP.service_ids(idp)
  # => ["shibboleth.RelyingPartyResolverService", "shibboleth.MetadataResolverService", "shibboleth.LoggingService" ...]
  ```

  """
  @spec service_ids(idp :: IdP.t()) :: list()
  def service_ids(%IdP{reloadable_services: values}) when is_nil(values) do
    []
  end

  def service_ids(idp) do
    Map.values(idp.reloadable_services)
  end

  @doc """
  Return a list of service aliases as atoms.

  These can be passed instead of the full Shibboleth service ID.

  ## Examples

  ```
  Shin.IdP.service_aliases(idp)
  # => [:relying_party_resolver, :metadata_resolver, :attribute_registry, :attribute_resolver, :attribute_filter ...]
  ```

  """
  @spec service_aliases(idp :: IdP.t()) :: list()
  def service_aliases(%IdP{reloadable_services: values}) when is_nil(values) do
    []
  end

  def service_aliases(idp) do
    Map.keys(idp.reloadable_services)
  end

  @doc """
  Checks if a service ID or service alias is present in the IdP configuration.

  Returns true or false

  ## Examples

    ```
    Shin.IdP.is_reloadable?(idp, :attribute_registry)
    # => true
    ```

  """
  @spec is_reloadable?(idp :: IdP.t(), service :: atom() | binary()) :: boolean()
  def is_reloadable?(idp, service) when is_atom(service) do
    Map.has_key?(idp.reloadable_services, service)
  end

  def is_reloadable?(idp, service) when is_binary(service) do
    IdP.service_ids(idp)
    |> Enum.member?(service)
  end

  @doc """
  Checks if a service ID or service alias is present in the IdP configuration and returns a normalised version.

  Returns the full Shibboleth IdP service ID if passed an alias atom.

  ## Examples

    ```
    Shin.IdP.validate_service(idp, :attribute_registry)
    # => "shibboleth.AttributeRegistryService"
    ```

  """
  @spec validate_service(idp :: IdP.t(), service :: atom() | binary()) :: {:ok, binary()}
  def validate_service(idp, service) when is_atom(service) do
    service_id = Map.get(idp.reloadable_services, service)
    if service_id do
      {:ok, service_id}
    else
      {:error, "Cannot find service #{service} in list of IdP's reloadable services"}
    end
  end

  def validate_service(idp, service) when is_binary(service) do
    if is_reloadable?(idp, service) do
      {:ok, service}
    else
      {:error, "Cannot find service #{service} in list of IdP's reloadable services"}
    end
  end

  @doc """
  Checks if a metric group is present in the IdP configuration and returns a normalised version.

  Returns an atom.

  ## Examples

    ```
    Shin.IdP.validate_metric_group(idp, "core")
    # => :core
    ```

  """
  @spec validate_metric_group(idp :: IdP.t(), service :: atom() | binary()) :: {:ok, atom()}
  def validate_metric_group(idp, group) when is_binary(group) do
    try do
      group = String.to_existing_atom(group)
      validate_metric_group(idp, group)
    rescue
      ArgumentError -> validate_metric_group(idp, :nope)
    end
  end

  def validate_metric_group(idp, group) when is_atom(group) do
    if Enum.member?(idp.metric_groups, group) do
      {:ok, group}
    else
      {:error, "IdP does not support metric group '#{group}'"}
    end
  end

  @doc """
  Returns the base metrics path (for all metrics) for an IdP

  ## Examples

    ```
    Shin.IdP.metrics_path(idp)
    # =>  metrics_path: "https://example.com/idp/profile/admin/metrics",
    ```

  """
  @spec metrics_path(idp :: IdP.t()) :: binary()
  def metrics_path(idp) do
    idp.metrics_path
  end

  @doc """
  Returns the base metrics path for the specified group at an IdP

  ## Examples

    ```
    Shin.IdP.metrics_path(idp, :core)
    # =>  metrics_path: "https://example.com/idp/profile/admin/metrics/core",
    ```

  """
  @spec metrics_path(idp :: IdP.t(), group :: atom() | binary()) :: binary()
  def metrics_path(idp, group) do
    "#{idp.metrics_path}/#{group}"
  end

  ####################################################################################################

  @spec validate_url(url :: binary, options :: list()) :: {:ok, binary} | {:error, binary}
  defp validate_url(url, options) do
    parsed_url = URI.parse(url)
    case parsed_url do
      %URI{scheme: nil} -> {:error, "Missing scheme (https://)"}
      %URI{scheme: scheme} when scheme not in ["http", "https"] -> {:error, "URL scheme is not http: or https:"}
      %URI{host: nil} -> {:error, "Missing hostname"}
      %URI{host: host} ->
        case :inet.gethostbyname(Kernel.to_charlist(host)) do
          {:ok, _} -> {:ok, url}
          {:error, _} ->
            if options[:no_dns_check] do
              Logger.warn "Invalid hostname (DNS lookup failed)"
              {:ok, url}
            else
              {:error, "Invalid hostname (DNS lookup failed)"}
            end

        end
    end
  end

  @spec validate_opts(opts :: list()) :: {:ok, list} | {:error, binary}
  defp validate_opts(opts) do
    {:ok, opts}
  end

  @spec merge(url :: binary, opts :: list()) :: map()
  defp merge(url, opts) do
    opt_map = Enum.into(opts, %{base_url: nil})
    %{opt_map | base_url: url}
  end

end
