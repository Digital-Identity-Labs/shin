defmodule Shin.IdP do

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
    managed_beans: "shibboleth.ManagedBeanService"
  }

  @enforce_keys [:base_url]

  @type t :: %IdP{
               base_url: binary(),
               metrics_path: binary(),
               reload_path: binary(),
               metric_groups: list(),
               reloadable_services: map(),
               no_dns_check: boolean(),
               timeout: integer()
             }

  defstruct [
    :base_url,
    metrics_path: "profile/admin/metrics",
    reload_path: "profile/admin/reload-service",
    metric_groups: @default_metric_groups,
    reloadable_services: @default_reloadable_services,
    no_dns_check: false,
    timeout: 2_000
  ]

  def configure(idp) when is_struct(idp) do
    {:ok, idp}
  end

  def configure(base_url, options \\ []) when is_binary(base_url) do
    with {:ok, url} <- validate_url(base_url, options),
         {:ok, opts} <- validate_opts(options) do
      {:ok, struct(IdP, merge(url, opts))}
    else
      err -> err
    end
  end

  def metric_groups(%IdP{metric_groups: values} = idp) when is_nil(values) do
    []
  end

  def metric_groups(idp) do
    idp.metric_groups
  end

  def service_ids(%IdP{reloadable_services: values} = idp) when is_nil(values) do
    []
  end

  def service_ids(idp) do
    Map.values(idp.reloadable_services)
  end

  def service_aliases(%IdP{reloadable_services: values} = idp) when is_nil(values) do
    []
  end

  def service_aliases(idp) do
    Map.keys(idp.reloadable_services)
  end

  def is_reloadable?(idp, service) when is_atom(service) do
    Map.has_key?(idp.reloadable_services, service)
  end

  def is_reloadable?(idp, service) when is_binary(service) do
    IdP.service_ids(idp)
    |> Enum.member?(service)
  end

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

  def metrics_path(idp) do
    idp.metrics_path
  end

  def metrics_path(idp, group) do
    "#{idp.metrics_path}/#{group}"
  end

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

  defp validate_opts(opts) do
    {:ok, opts}
  end

  defp merge(url, opts) do
    opt_map = Enum.into(opts, %{base_url: nil})
    %{opt_map | base_url: url}
  end

end