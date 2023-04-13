defmodule ShinMetricsTest do
  use ExUnit.Case

  alias Shin.Metrics

  @big_metrics MetricsExamples.complete_parsed()

  setup do
    bypass = Bypass.open()
    {:ok, bypass: bypass}
  end

  describe "query/1" do

    test "will return a map of raw metrics data if the service is available", %{bypass: bypass} do

      Bypass.expect_once(
        bypass,
        "GET",
        "/idp/profile/admin/metrics",
        fn conn ->
          Plug.Conn.resp(conn, 200, MetricsExamples.complete_raw())
          |> Plug.Conn.merge_resp_headers([{"content-type", "application/json"}])
        end
      )

      {:ok, idp} = Shin.idp(idp_endpoint_url(bypass.port), retries: 0)

      assert {
               :ok,
               %{
                 "gauges" => %{
                   "net.shibboleth.idp.version" => %{
                     "value" => "4.2.1"
                   }
                 }
               }
             } = Metrics.query(idp)
    end

    test "will produce a decent error if service is unavailable", %{bypass: bypass} do

      Bypass.expect(
        bypass,
        "GET",
        "/idp/profile/admin/metrics",
        fn conn ->
          Plug.Conn.resp(conn, 500, "A fake error has occurred")
          |> Plug.Conn.merge_resp_headers([{"content-type", "text/plain"}])
        end
      )

      {:ok, idp} = Shin.idp(idp_endpoint_url(bypass.port), retries: 0)


      assert {:error, "Error 500"} = Metrics.query(idp)
    end

    test "can be passed an IdP record (expected)", %{bypass: bypass} do

      Bypass.expect_once(
        bypass,
        "GET",
        "/idp/profile/admin/metrics",
        fn conn ->
          Plug.Conn.resp(conn, 200, MetricsExamples.complete_raw())
          |> Plug.Conn.merge_resp_headers([{"content-type", "application/json"}])
        end
      )

      {:ok, idp} = Shin.idp(idp_endpoint_url(bypass.port), retries: 0)

      assert {:ok, %{"gauges" => _things}} = Shin.metrics(idp)

    end

    test "cannot be passed a base URL for the IdP", %{bypass: bypass} do

      url = idp_endpoint_url(bypass.port)

      assert {:error, "IdP record is required"} = Metrics.query(url)
    end

  end

  describe "query/2" do

    test "will return a map of a subset of raw metrics data if the service is available and the group is known",
         %{bypass: bypass} do
      Bypass.expect_once(
        bypass,
        "GET",
        "/idp/profile/admin/metrics/core",
        fn conn ->
          Plug.Conn.resp(conn, 200, MetricsExamples.core_raw())
          |> Plug.Conn.merge_resp_headers([{"content-type", "application/json"}])
        end
      )

      {:ok, idp} = Shin.idp(idp_endpoint_url(bypass.port), retries: 0)

      assert {
               :ok,
               %{
                 "gauges" => %{
                   "cores.available" => _
                 }
               }

             } = Metrics.query(idp, :core)
    end

    test "will complain if passed an unknown group", %{bypass: bypass} do
      {:ok, idp} = Shin.idp(idp_endpoint_url(bypass.port), retries: 0)
      assert {:error, "IdP does not support metric group 'baboon'"} = Metrics.query(idp, :baboon)
    end

    test "will produce a decent error if service is unavailable", %{bypass: bypass} do

      Bypass.expect(
        bypass,
        "GET",
        "/idp/profile/admin/metrics/core",
        fn conn ->
          Plug.Conn.resp(conn, 500, "A fake error has occurred")
          |> Plug.Conn.merge_resp_headers([{"content-type", "text/plain"}])
        end
      )

      {:ok, idp} = Shin.idp(idp_endpoint_url(bypass.port), retries: 0)

      assert {:error, "Error 500"} = Metrics.query(idp, :core)
    end

    test "can be passed an IdP record (expected)", %{bypass: bypass} do

      Bypass.expect_once(
        bypass,
        "GET",
        "/idp/profile/admin/metrics/core",
        fn conn ->
          Plug.Conn.resp(conn, 200, MetricsExamples.core_raw())
          |> Plug.Conn.merge_resp_headers([{"content-type", "application/json"}])
        end
      )

      {:ok, idp} = Shin.idp(idp_endpoint_url(bypass.port), retries: 0)

      assert {:ok, %{"gauges" => _things}} = Metrics.query(idp, :core)

    end

    test "cannot be passed a base URL for the IdP", %{bypass: bypass} do
      
      url = idp_endpoint_url(bypass.port)

      assert {:error, "IdP record is required"} = Metrics.query(url, :core)

    end

  end

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

  defp idp_endpoint_url(port), do: "http://localhost:#{port}/idp"

end
