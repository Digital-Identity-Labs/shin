defmodule ShinTest do
  use ExUnit.Case, async: false

  doctest Shin

  alias Shin
  alias Shin.IdP

  ###  setup_all do
  ###    Tesla.Mock.mock_global(
  ###      fn
  ###        %{
  ###          method: :get,
  ###          url: "https://login.localhost.demo.university/idp/profile/admin/reload-service"
  ###        } ->
  ###          %Tesla.Env{status: 200, body: "Configuration reloaded for 'shibboleth.MetadataResolverService'\n"}
  ###
  ###        %{
  ###          method: :get,
  ###          url: "https://login-miss.localhost.demo.university/idp/profile/admin/reload-service"
  ###        } ->
  ###          %Tesla.Env{status: 404, body: "Error 404 Page Not Found\n"}
  ###
  ###        %{
  ###          method: :get,
  ###          url: "https://login-error.localhost.demo.university/idp/profile/admin/reload-service"
  ###        } ->
  ###          %Tesla.Env{status: 500, body: "Error 500 Guru Meditation\n"}
  ###
  ###        %{
  ###          method: :get,
  ###          url: "https://login.localhost.demo.university/idp/profile/admin/metrics"
  ###        } ->
  ###          %Tesla.Env{status: 200, body: MetricsExamples.complete()}
  ###
  ###        %{
  ###          method: :get,
  ###          url: "https://login-error.localhost.demo.university/idp/profile/admin/metrics"
  ###        } ->
  ###          %Tesla.Env{status: 500, body: "Error 500\n"}
  ###
  ###        %{
  ###          method: :get,
  ###          url: "https://login.localhost.demo.university/idp/profile/admin/metrics/core"
  ###        } ->
  ###          %Tesla.Env{status: 200, body: MetricsExamples.core()}
  ###
  ###        %{
  ###          method: :get,
  ###          url: "https://login-error.localhost.demo.university/idp/profile/admin/metrics/core"
  ###        } ->
  ###          %Tesla.Env{status: 500, body: "Error 404 Page Not Found\n"}
  ###
  ###      end
  ###    )
  ###    :ok
  ###  end
  ##
  ###  {:ok, good_idp} = Shin.idp("https://login.localhost.demo.university/idp")
  ###  @good_idp good_idp
  ###
  ###  {:ok, miss_idp} = Shin.idp("https://login-miss.localhost.demo.university/idp")
  ###  @miss_idp miss_idp
  ###
  ###  {:ok, error_idp} = Shin.idp("https://login-error.localhost.demo.university/idp")
  ###  @error_idp error_idp
  ##

  setup do
    bypass = Bypass.open()
    {:ok, bypass: bypass}
  end

  describe "idp/2" do

    test "returns an IdP struct if passed a valid URL, without options" do
      assert {:ok, %IdP{}} = Shin.idp("https://indiid.net/idp")
    end

    test "accepts options and returns an IdP with adjusted defaults" do
      assert {:ok, %IdP{reload_path: "profile/admin/reload-service2"}} = Shin.idp(
               "https://indiid.net/idp",
               [reload_path: "profile/admin/reload-service2"]
             )
    end

    test "will not accept a bad URL" do
      assert {:error, _} = Shin.idp("htps://indiid.net/idp")
    end

    test "will not normally accept a URL with unfindable hostname" do
      assert {:error, _} = Shin.idp("https://dancing.dancing.newt")
    end

    test "will allow an unfindable hostname if the :no_dns_check option is set to true" do
      assert {:error, _} = Shin.idp("htps://indiid.net/idp", no_dns_check: true)
    end

  end

  describe "reload_service/2" do

    test "will reload an existing and known reloadable service, using the service ID", %{bypass: bypass} do

      Bypass.expect_once(
        bypass,
        "GET",
        "/idp/profile/admin/reload-service",
        fn conn ->
          Plug.Conn.resp(conn, 200, "Configuration reloaded for 'shibboleth.MetadataResolverService'\n")
        end
      )

      {:ok, idp} = Shin.idp(idp_endpoint_url(bypass.port))
      assert {:ok, "Configuration reloaded for 'shibboleth.MetadataResolverService'"} =
               Shin.reload_service(idp, "shibboleth.MetadataResolverService")
    end

    test "will reload and existing and known reloadable service, using an alias", %{bypass: bypass} do

      Bypass.expect_once(
        bypass,
        "GET",
        "/idp/profile/admin/reload-service",
        fn conn ->
          Plug.Conn.resp(conn, 200, "Configuration reloaded for 'shibboleth.MetadataResolverService'\n")
        end
      )

      {:ok, idp} = Shin.idp(idp_endpoint_url(bypass.port))
      assert {:ok, "Configuration reloaded for 'shibboleth.MetadataResolverService'"} =
               Shin.reload_service(idp, :metadata_resolver)
    end

    test "will complain if passed an unknown service ID", %{bypass: bypass} do
      {:ok, idp} = Shin.idp(idp_endpoint_url(bypass.port))
      assert {:error, _} = Shin.reload_service(idp, "shibboleth.BetadataResolverService")
    end

    test "will not complain if a new service ID has been added to the IdP configuration", %{bypass: bypass} do

      Bypass.expect_once(
        bypass,
        "GET",
        "/idp/profile/admin/reload-service",
        fn conn ->
          Plug.Conn.resp(conn, 200, "Configuration reloaded for 'shibboleth.MetadataResolverService'\n")
        end
      )

      {:ok, idp} = Shin.idp(
        idp_endpoint_url(bypass.port),
        reloadable_services: %{
          metadata_resolver: "shibboleth.BetadataResolverService"
        }
      )

      assert {:ok, _} = Shin.reload_service(idp, "shibboleth.BetadataResolverService")
    end

    test "will complain if passed an unknown alias", %{bypass: bypass} do
      {:ok, idp} = Shin.idp(idp_endpoint_url(bypass.port), retries: 0)
      assert {:error, _} = Shin.reload_service(idp, :whatever_resolver)
    end

    test "will produce a decent error if URL or server is not found", %{bypass: bypass} do

      Bypass.expect_once(
        bypass,
        "GET",
        "/idp/profile/admin/reload-service",
        fn conn ->
          Plug.Conn.resp(conn, 404, "Not found")
          |> Plug.Conn.merge_resp_headers([{"content-type", "text/plain"}])
        end
      )

      {:ok, idp} = Shin.idp(idp_endpoint_url(bypass.port), retries: 0)
      assert {:error, _} = Shin.reload_service(idp, :metadata_resolver)
    end

    test "will produce a decent error if server has error", %{bypass: bypass} do

      Bypass.expect(
        bypass,
        "GET",
        "/idp/profile/admin/reload-service",
        fn conn ->
          Plug.Conn.resp(conn, 500, "A fake error has occurred")
          |> Plug.Conn.merge_resp_headers([{"content-type", "text/plain"}])
        end
      )
      {:ok, idp} = Shin.idp(idp_endpoint_url(bypass.port), retries: 0)
      assert {:error, _} = Shin.reload_service(idp, :metadata_resolver)
    end

    test "can be passed an IdP record (expected)", %{bypass: bypass} do

      Bypass.expect_once(
        bypass,
        "GET",
        "/idp/profile/admin/reload-service",
        fn conn ->
          Plug.Conn.resp(conn, 200, "Configuration reloaded for 'shibboleth.MetadataResolverService'\n")
        end
      )

      {:ok, idp} = Shin.idp(idp_endpoint_url(bypass.port), retries: 0)
      assert {:ok, "Configuration reloaded for 'shibboleth.MetadataResolverService'"} =
               Shin.reload_service(idp, "shibboleth.MetadataResolverService")
    end

    test "can be passed a base URL for the IdP", %{bypass: bypass} do

      Bypass.expect_once(
        bypass,
        "GET",
        "/idp/profile/admin/reload-service",
        fn conn ->
          Plug.Conn.resp(conn, 200, "Configuration reloaded for 'shibboleth.MetadataResolverService'\n")
        end
      )

      idp_url = idp_endpoint_url(bypass.port)

      assert {:ok, "Configuration reloaded for 'shibboleth.MetadataResolverService'"} =
               Shin.reload_service(idp_url, "shibboleth.MetadataResolverService")
    end

  end

  describe "metrics/1" do

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
             } = Shin.metrics(idp)
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


      assert {:error, "Error 500"} = Shin.metrics(idp)
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

    test "can be passed a base URL for the IdP", %{bypass: bypass} do

      Bypass.expect_once(
        bypass,
        "GET",
        "/idp/profile/admin/metrics",
        fn conn ->
          Plug.Conn.resp(conn, 200, MetricsExamples.complete_raw())
          |> Plug.Conn.merge_resp_headers([{"content-type", "application/json"}])
        end
      )

      url = idp_endpoint_url(bypass.port)

      assert {:ok, %{"gauges" => _things}} = Shin.metrics(url)
    end

  end

  describe "metrics/2" do

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

             } = Shin.metrics(idp, :core)
    end

    test "will complain if passed an unknown group", %{bypass: bypass} do
      {:ok, idp} = Shin.idp(idp_endpoint_url(bypass.port), retries: 0)
      assert {:error, "IdP does not support metric group 'baboon'"} = Shin.metrics(idp, :baboon)
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

      assert {:error, "Error 500"} = Shin.metrics(idp, :core)
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

      assert {:ok, %{"gauges" => _things}} = Shin.metrics(idp, :core)

    end

    test "can be passed a base URL for the IdP", %{bypass: bypass} do

      Bypass.expect_once(
        bypass,
        "GET",
        "/idp/profile/admin/metrics/core",
        fn conn ->
          Plug.Conn.resp(conn, 200, MetricsExamples.complete_raw())
          |> Plug.Conn.merge_resp_headers([{"content-type", "application/json"}])
        end
      )

      url = idp_endpoint_url(bypass.port)

      assert {:ok, %{"gauges" => _things}} = Shin.metrics(url, :core)

    end

  end

  describe "report/1" do

    test "will return a default struct containing processed metrics (system info)", %{bypass: bypass} do

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

      assert {:ok, %Shin.Reports.SystemInfo{hostname: _}} = Shin.report(idp)
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

      assert {:error, "Error 500"} = Shin.report(idp)
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

      assert {:ok, %Shin.Reports.SystemInfo{hostname: _}} = Shin.report(idp)

    end

    test "can be passed a base URL for the IdP", %{bypass: bypass} do

      Bypass.expect_once(
        bypass,
        "GET",
        "/idp/profile/admin/metrics",
        fn conn ->
          Plug.Conn.resp(conn, 200, MetricsExamples.complete_raw())
          |> Plug.Conn.merge_resp_headers([{"content-type", "application/json"}])
        end
      )

      url = idp_endpoint_url(bypass.port)

      assert {:ok, %Shin.Reports.SystemInfo{hostname: _}} = Shin.report(url)
    end

  end

  describe "report/2" do

    test "will return a struct containing processed metrics as specified by the report Module", %{bypass: bypass} do

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

      assert {:ok, %Shin.Reports.IdPInfo{uptime: _}} = Shin.report(idp, Shin.Reports.IdPInfo)
    end

    test "will return a struct containing processed metrics as specified by the report alias", %{bypass: bypass} do

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

      assert {:ok, %Shin.Reports.SystemInfo{hostname: _}} = Shin.report(idp, :system_info)
    end

    test "will complain if passed an unknown alias", %{bypass: bypass} do

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

      assert {:error, _} = Shin.report(idp, :badgers)
    end

    test "will produce a decent error if service is unavailable", %{bypass: bypass} do

      Bypass.expect_once(
        bypass,
        "GET",
        "/idp/profile/admin/metrics",
        fn conn ->
          Plug.Conn.resp(conn, 500, "OOPS")
        end
      )

      {:ok, idp} = Shin.idp(idp_endpoint_url(bypass.port), retries: 0)

      assert {:error, "Error 500"} = Shin.report(idp, :system_info)
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

      assert {:ok, %Shin.Reports.SystemInfo{hostname: _}} = Shin.report(idp, Shin.Reports.SystemInfo)
    end

    test "can be passed a base URL for the IdP", %{bypass: bypass} do

      Bypass.expect_once(
        bypass,
        "GET",
        "/idp/profile/admin/metrics",
        fn conn ->
          Plug.Conn.resp(conn, 200, MetricsExamples.complete_raw())
          |> Plug.Conn.merge_resp_headers([{"content-type", "application/json"}])
        end
      )

      idp_url = idp_endpoint_url(bypass.port)

      assert {:ok, %Shin.Reports.SystemInfo{hostname: _}} = Shin.report(
               idp_url,
               :system_info
             )
    end

  end

  defp idp_endpoint_url(port), do: "http://localhost:#{port}/idp"

end
