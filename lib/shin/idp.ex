defmodule Shin.IdP do

  alias __MODULE__

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

  @enforce_keys [:base_url]

  defstruct [
    :base_url,
    metrics_path: "profile/admin/metrics",
    reload_path: "profile/admin/reload-service",
    metric_groups: @default_metric_groups
  ]

  def configure(base_url, options \\ []) do
    with {:ok, url} <- validate_url(base_url),
         {:ok, opts} <- validate_opts(options) do
      struct(IdP, merge(url, opts))
    else
      err -> err
    end
  end

  defp validate_url(url) do
    parsed_url = URI.parse(url)
    case parsed_url do
      %URI{scheme: nil} -> {:error, "Missing scheme (https://)"}
      %URI{host: nil} -> {:error, "Missing hostname"}
      %URI{host: host} ->
        case :inet.gethostbyname(Kernel.to_charlist(host)) do
          {:ok, _} -> {:ok, url}
          {:error, _} -> {:error, "Invalid hostname (DNS lookup failed)"}
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