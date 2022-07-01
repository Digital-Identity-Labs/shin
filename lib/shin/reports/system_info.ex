defmodule Shin.Reports.SystemInfo do

  @moduledoc false

  alias __MODULE__
  alias Shin.Metrics

  @mapper %{
    cores: "cores.available",
    hostname: "host.name",
    java_classpath: "java.class.path",
    java_home: "java.home",
    java_vendor: "java.vendor",
    java_vendor_url: "java.vendor.url",
    java_version: "java.version",
    memory_free: "memory.free.bytes",
    memory_max: "memory.max.bytes",
    memory_used: "memory.used.bytes",
    memory_usage: "memory.usage",
    os_arch: "os.arch",
    os_name: "os.name",
    os_version: "os.version"
  }

  defstruct Map.keys(@mapper)

  def req_group do
    :core
  end

  def produce(metrics) do
    struct(SystemInfo, Metrics.map_gauges(metrics, @mapper))
  end

end