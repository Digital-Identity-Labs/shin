defmodule Shin.Reports.ServicesInfo do

  @moduledoc false

  alias __MODULE__
  alias Shin.Metrics

  @mapper %{
    relying_party_resolver_reload_attempt_at: "net.shibboleth.idp.relyingparty.reload.attempt",
    relying_party_resolver_reload_success_at: "net.shibboleth.idp.relyingparty.reload.success",
    relying_party_resolver_reload_error_at: "net.shibboleth.idp.relyingparty.reload.error",
    metadata_resolver_reload_attempt_at: "net.shibboleth.idp.metadata.reload.attempt",
    metadata_resolver_reload_success_at: "net.shibboleth.idp.metadata.reload.success",
    metadata_resolver_reload_error_at: "net.shibboleth.idp.metadata.reload.error",
    attribute_registry_reload_attempt_at: "net.shibboleth.idp.attribute.registry.reload.attempt",
    attribute_registry_reload_success_at: "net.shibboleth.idp.attribute.registry.reload.success",
    attribute_registry_reload_error_at: "net.shibboleth.idp.attribute.registry.reload.error",
    attribute_resolver_reload_attempt_at: "net.shibboleth.idp.attribute.resolver.reload.attempt",
    attribute_resolver_reload_success_at: "net.shibboleth.idp.attribute.resolver.reload.success",
    attribute_resolver_reload_error_at: "net.shibboleth.idp.attribute.resolve.reload.errorr",
    attribute_filter_reload_attempt_at: "net.shibboleth.idp.attribute.filter.reload.attempt",
    attribute_filter_reload_success_at: "net.shibboleth.idp.attribute.filter.reload.success",
    attribute_filter_reload_error_at: "net.shibboleth.idp.attribute.filter.reload.error",
    nameid_generator_reload_attempt_at: "net.shibboleth.idp.nameid.reload.attempt",
    nameid_generator_reload_success_at: "net.shibboleth.idp.nameid.reload.success",
    nameid_generator_reload_error_at: "net.shibboleth.idp.nameid.reload.error",
    access_control_reload_attempt_at: "net.shibboleth.idp.accesscontrol.reload.attempt",
    access_control_reload_success_at: "net.shibboleth.idp.accesscontrol.reload.success",
    access_control_reload_error_at: "net.shibboleth.idp.accesscontrol.reload.error",
    cas_registry_reload_attempt_at: "net.shibboleth.idp.cas.registry.reload.attempt",
    cas_registry_reload_success_at: "net.shibboleth.idp.cas.registry.reload.success",
    cas_registry_reload_error_at: "net.shibboleth.idp.cas.registry.reload.error",
    managed_beans_reload_attempt_at: "net.shibboleth.idp.managedbean.reload.attempt",
    managed_beans_reload_success_at: "net.shibboleth.idp.managedbean.reload.success",
    managed_beans_reload_error_at: "net.shibboleth.idp.managedbean.reload.error",
    logging_reload_attempt_at: "net.shibboleth.idp.logging.reload.attempt",
    logging_reload_success_at: "net.shibboleth.idp.logging.reload.success",
    logging_reload_error_at: "net.shibboleth.idp.logging.reload.error"
  }

  defstruct Map.keys(@mapper)

  def req_group do
    :core
  end

  def produce(metrics) do
    data = Metrics.map_gauges(metrics, @mapper)
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
    struct(ServicesInfo, data)
  end


end
