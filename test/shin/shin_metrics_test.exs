defmodule ShinMetricsTest do
  use ExUnit.Case

  alias Shin.Metrics

  @big_metrics MetricsExamples.complete()

  describe "gauge_ids/1" do
    test "returns a list of all gauges ids/keys in the metrics map" do
      ids = Metrics.gauge_ids(@big_metrics)
      assert Enum.member?(ids, "java.vendor")
      assert Enum.member?(ids, "host.name")
    end
  end

  describe "gauge/2" do
    test "returns the value for the specified gauge" do
      assert "idpprod1" = Metrics.gauge(@big_metrics, "host.name")
    end
  end

  describe "gauges/1" do
    test "returns a map of all gauges and their values" do
      assert %{"memory.free.megs" => _, "memory.max.megs" => _} = Metrics.gauges(@big_metrics)
    end
  end

  describe "map_gauges/2" do
    test "returns a map of each specified gauge and its value" do
      assert %{h: "idpprod1", r: 2048} = Metrics.map_gauges(@big_metrics, %{h: "host.name", r: "memory.max.megs"})
    end
  end

  describe "timer_ids/1" do
    test "returns a list of all timer ids/keys in the metrics map" do
      ids = Metrics.timer_ids(@big_metrics)
      assert Enum.member?(ids, "org.opensaml.saml.metadata.resolver.impl.LocalDynamicMetadataResolver.exOverride.timer.resolve")
    end
  end

  describe "timer/2" do
    test "returns the map for the specified timer" do
      assert %{"count" => 1, "duration_units" => "seconds"} = Metrics.timer(@big_metrics, "org.opensaml.saml.metadata.resolver.impl.LocalDynamicMetadataResolver.exOverride.timer.resolve")
    end
  end

  describe "timers/1" do
    test "returns a map of all timers and their values (maps)" do
      assert %{"org.opensaml.saml.metadata.resolver.impl.LocalDynamicMetadataResolver.exOverride.timer.resolve" => %{}} = Metrics.timers(@big_metrics)
      assert Metrics.timers(@big_metrics)
    end
  end

  describe "map_timers/2" do
    test "returns a map of each specified gauge and its value" do
      assert %{x: %{"count" => 1}} = Metrics.map_timers(@big_metrics, %{x: "org.opensaml.saml.metadata.resolver.impl.LocalDynamicMetadataResolver.exOverride.timer.resolve"})
    end
  end

end

