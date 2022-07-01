defmodule Shin.Reports.IdPInfo do

  @moduledoc false

  alias __MODULE__
  alias Shin.Metrics

  @mapper %{
    started_at: "net.shibboleth.idp.starttime",
    uptime: "net.shibboleth.idp.uptime",
    idp_version: "net.shibboleth.idp.version",
    lib_version: "org.opensaml.version"
  }

  defstruct Map.keys(@mapper)

  def req_group do
    :idp
  end

  def produce(metrics) do
    struct(IdPInfo, Metrics.map_gauges(metrics, @mapper))
  end

end
