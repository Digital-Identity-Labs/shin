# Shin

`Shin` is a simple Elixir client for the [Shibboleth IdP's](https://www.shibboleth.net/products/) admin features.
Currently it can collect metrics and trigger service reloads.

Shin can be used to gather information about your IdP servers such as Java version and IdP version, and can also collect any
other information defined as a metric within the IdP. Shin can return the raw data or reformat it into simpler reports.

The Shibboleth IdP will automatically reload valid configuration files but may stop retrying if passed an incorrect file. 
Shin can be used to prompt the IdP to immediately reload parts of its configuration.

[![Run in Livebook](https://livebook.dev/badge/v1/blue.svg)](https://livebook.dev/run?url=https%3A%2F%2Fraw.githubusercontent.com%2FDigital-Identity-Labs%2Fshin%2Fmain%2Fshin_notebook.livemd)


## Installation

The package can be installed by adding `shin` to your list of
dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:shin, "~> 0.1.0"}
  ]
end
```

## Overview

### Defining an IdP target 

To define an IdP using a default configuration you only need the base URL of the IdP service

```elixir

{:ok, idp} = Shin.idp("https://idp.example.com/idp")
# => 
#{:ok,
#  %Shin.IdP{
#    base_url: "https://idp.example.com/idp",
#    metric_groups: [:core, :idp, :logging, :access, :metadata, :nameid,
#      :relyingparty, :registry, :resolver, :filter, :cas, :bean],
#    metrics_path: "profile/admin/metrics",
#    no_dns_check: false,
#    reload_path: "profile/admin/reload-service",
#    reloadable_services: %{
#      access_control: "shibboleth.ReloadableAccessControlService",
#      attribute_filter: "shibboleth.AttributeFilterService",
#      attribute_registry: "shibboleth.AttributeRegistryService",
#      attribute_resolver: "shibboleth.AttributeResolverService",
#      cas_registry: "shibboleth.ReloadableCASServiceRegistry",
#      managed_beans: "shibboleth.ManagedBeanService",
#      metadata_resolver: "shibboleth.MetadataResolverService",
#      nameid_generator: "shibboleth.NameIdentifierGenerationService",
#      relying_party_resolver: "shibboleth.RelyingPartyResolverService"
#    },
#    timeout: 2000
#  }}
```

If your IdP has different paths, metrics groups or reloadable services you can specify them as options.

Functions in the top-level Shin module can also be passed a based URL if no configuration is needed.

### Downloading raw metrics

```elixir

{:ok, metrics} = Shin.metrics(idp)

{:ok, metrics} = Shin.metrics(idp, :core)

list_of_gauges = Shin.Metrics.gauge_ids(metrics)
hostname = Shin.Metrics.gauge(metrics, "host.name")

```

### Producing a simplified report

```elixir

{:ok, report} = Shin.report(idp, :system_info)

report.cores
=> 4

```

### Triggering a service reload

```elixir

{:ok, message} = Shin.reload_service(idp, "shibboleth.AttributeFilterService")

{:ok, message} = Shin.reload_service(idp, :attribute_filter)

```

## Example Script

This script outputs a small table showing the Java version used by each IdP

```elixir
#!/usr/bin/env elixir

Mix.install(
  [
    {:shin, "~> 0.1"},
    {:table_rex, "~> 3.1.1"}
  ]
)

urls = [
  "https://idp1.example.com/idp",
  "https://idp2.example.com/idp",
]

urls
|> Enum.map(
     fn url -> Shin.report(url)
               |> case do
                    {:ok, report} -> [url, report.java_version, report.java_vendor]
                    {:error, _msg} -> [url, "error", "error"]
                  end
     end
   )
|> TableRex.quick_render!(["IdP", "Java Version", "Java Vendor"])
|> IO.puts

```

## Requirements

* Shibboleth IdP v3 or above (Shin is only tested against v4)
* IP address [access control](https://shibboleth.atlassian.net/wiki/spaces/IDP4/pages/1265631516/AccessControlConfiguration) enabled for the client's IP address for the IdP's admin endpoints
* Elixir 12 or greater, Erlang 24 or greater

## Limitations

* Only IP address-based authnz is supported, but other methods may be added in later versions.

## API Documentation

Full API documentation can be found at
[https://hexdocs.pm/shin](https://hexdocs.pm/shin).

## Contributing

You can request new features by creating an [issue](https://github.com/Digital-Identity-Labs/shin/issues),
or submit a [pull request](https://github.com/Digital-Identity-Labs/shin/pulls) with your contribution.

## References

* [Shibboleth IdP v4 Metrics Docs](https://shibboleth.atlassian.net/wiki/spaces/IDP4/pages/1265631722/MetricsConfiguration)
* [Shibboleth IdP v4 Reloadable Services Docs](https://shibboleth.atlassian.net/wiki/spaces/IDP4/pages/1265631674/ReloadableServices)
* [Shibboleth IdP v4 Access Control](https://shibboleth.atlassian.net/wiki/spaces/IDP4/pages/1265631516/AccessControlConfiguration)
* Shin is named after the [twenty-first letter of the Semitic abjads](https://en.wikipedia.org/wiki/Shin_(letter))

## Copyright and License

Copyright (c) 2022 Digital Identity Ltd, UK

Shin is MIT licensed.
