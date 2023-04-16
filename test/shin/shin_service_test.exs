defmodule ShinServiceTest do
  use ExUnit.Case

  alias Shin.IdP
  alias Shin.Service

  @big_metrics MetricsExamples.complete_parsed()

  setup do
    bypass = Bypass.open()
    {:ok, bypass: bypass}
  end


  describe "query/3" do

    test "returns a summary of reload status for known services when passed a service ID", %{bypass: bypass} do

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
                 ok: true,
                 reload_attempted_at: ~U[2022-06-22 07:54:10.438366Z],
                 reload_failed_at: nil,
                 reload_requested: true,
                 reload_succeeded_at: ~U[2022-06-22 07:54:10.438366Z],
                 service: "shibboleth.RelyingPartyResolverService"
               }
             } = Service.query(idp, "shibboleth.RelyingPartyResolverService")
    end

    test "returns a summary of reload status for known services when passed a service alias", %{bypass: bypass} do

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
                 ok: true,
                 reload_attempted_at: ~U[2022-06-22 07:54:10.438366Z],
                 reload_failed_at: nil,
                 reload_requested: true,
                 reload_succeeded_at: ~U[2022-06-22 07:54:10.438366Z],
                 service: "shibboleth.RelyingPartyResolverService"
               }
             } = Service.query(idp, :relying_party_resolver)
    end

    test "returns an error tuple if the service is unknown for that IdP", %{bypass: bypass} do
      {:ok, idp} = Shin.idp(idp_endpoint_url(bypass.port), retries: 0)
      assert {:error, _} = Service.query(idp, :frying_party_resolver)
    end

    test "returns an error tuple if the IdP is a string, not a struct", %{bypass: bypass} do
      url = idp_endpoint_url(bypass.port)
      assert {:error, "IdP record is required"} = Service.query(url, :relying_party_resolver)
    end

    test "the results show ok: true for services that have never been asked to reload", %{bypass: bypass} do
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

      assert {:ok, %{ok: true}} = Service.query(idp, "shibboleth.ReloadableAccessControlService")
    end

    test "the results show ok: true for services that have reloaded successfully at most recent reload request",
         %{bypass: bypass} do
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
                 ok: true,
                 reload_attempted_at: ~U[2022-06-22 07:54:10.438366Z],
                 reload_failed_at: nil,
                 reload_requested: true,
                 reload_succeeded_at: ~U[2022-06-22 07:54:10.438366Z],
                 service: "shibboleth.RelyingPartyResolverService"
               }
             } = Service.query(idp, "shibboleth.RelyingPartyResolverService")
    end

    test "the results show ok: false for services that have reloaded unsuccessfully at most recent  reload request",
         %{bypass: bypass} do
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

      assert {:ok, %{ok: false}} = Service.query(idp, "shibboleth.LoggingService")

    end

  end

  describe "query!/3" do

    test "returns a summary of reload status for known services when passed a service ID", %{bypass: bypass} do

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

      assert %{
               ok: true,
               reload_attempted_at: ~U[2022-06-22 07:54:10.438366Z],
               reload_failed_at: nil,
               reload_requested: true,
               reload_succeeded_at: ~U[2022-06-22 07:54:10.438366Z],
               service: "shibboleth.RelyingPartyResolverService"
             } = Service.query!(idp, "shibboleth.RelyingPartyResolverService")
    end

    test "returns a summary of reload status for known services when passed a service alias", %{bypass: bypass} do

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

      assert %{
               ok: true,
               reload_attempted_at: ~U[2022-06-22 07:54:10.438366Z],
               reload_failed_at: nil,
               reload_requested: true,
               reload_succeeded_at: ~U[2022-06-22 07:54:10.438366Z],
               service: "shibboleth.RelyingPartyResolverService"
             } = Service.query!(idp, :relying_party_resolver)
    end

    test "raises an exception if the service is unknown for that IdP", %{bypass: bypass} do
      {:ok, idp} = Shin.idp(idp_endpoint_url(bypass.port), retries: 0)
      assert_raise RuntimeError, "Cannot find service frying_party_resolver in list of IdP's reloadable services", fn ->
        Service.query!(idp, :frying_party_resolver)
      end
    end

    test "raises an exception if the IdP is a string, not a struct", %{bypass: bypass} do
      url = idp_endpoint_url(bypass.port)
      assert_raise RuntimeError, "IdP record is required", fn ->
        Service.query!(url, :relying_party_resolver)
      end
    end

    test "the results show ok: true for services that have never been asked to reload", %{bypass: bypass} do
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

      assert %{ok: true} = Service.query!(idp, "shibboleth.ReloadableAccessControlService")
    end

    test "the results show ok: true for services that have reloaded successfully at most recent reload request",
         %{bypass: bypass} do
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

      assert %{
               ok: true,
               reload_attempted_at: ~U[2022-06-22 07:54:10.438366Z],
               reload_failed_at: nil,
               reload_requested: true,
               reload_succeeded_at: ~U[2022-06-22 07:54:10.438366Z],
               service: "shibboleth.RelyingPartyResolverService"
             } = Service.query!(idp, "shibboleth.RelyingPartyResolverService")
    end

    test "the results show ok: false for services that have reloaded unsuccessfully at most recent  reload request",
         %{bypass: bypass} do
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

      assert %{ok: false} = Service.query!(idp, "shibboleth.LoggingService")

    end

  end

  describe "reload/3" do

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
               Service.reload(idp, "shibboleth.MetadataResolverService")
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
               Service.reload(idp, :metadata_resolver)
    end

    test "will complain if passed an unknown service ID", %{bypass: bypass} do
      {:ok, idp} = Shin.idp(idp_endpoint_url(bypass.port))
      assert {:error, _} = Service.reload(idp, "shibboleth.BetadataResolverService")
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

      assert {:ok, _} = Service.reload(idp, "shibboleth.BetadataResolverService")
    end

    test "will complain if passed an unknown alias", %{bypass: bypass} do
      {:ok, idp} = Shin.idp(idp_endpoint_url(bypass.port), retries: 0)
      assert {:error, _} = Service.reload(idp, :whatever_resolver)
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
      assert {:error, _} = Service.reload(idp, :metadata_resolver)
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
      assert {:error, _} = Service.reload(idp, :metadata_resolver)
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
               Service.reload(idp, "shibboleth.MetadataResolverService")
    end

    test "cannot be passed a base URL for the IdP", %{bypass: bypass} do

      idp_url = idp_endpoint_url(bypass.port)

      assert {:error, "IdP record is required"} =
               Service.reload(idp_url, "shibboleth.MetadataResolverService")
    end

  end

  describe "reload!/3" do

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
      assert "Configuration reloaded for 'shibboleth.MetadataResolverService'" =
               Service.reload!(idp, "shibboleth.MetadataResolverService")
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
      assert "Configuration reloaded for 'shibboleth.MetadataResolverService'" =
               Service.reload!(idp, :metadata_resolver)
    end

    test "will complain if passed an unknown service ID", %{bypass: bypass} do
      {:ok, idp} = Shin.idp(idp_endpoint_url(bypass.port), retries: 0)
      assert_raise RuntimeError,
                   "Could not reload service shibboleth.BetadataResolverService: Cannot find service shibboleth.BetadataResolverService in list of IdP's reloadable services!",
                   fn ->
                     Service.reload!(idp, "shibboleth.BetadataResolverService")
                   end
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

      assert "Configuration reloaded for 'shibboleth.MetadataResolverService'" = Service.reload!(
               idp,
               "shibboleth.BetadataResolverService"
             )
    end

    test "will complain if passed an unknown alias", %{bypass: bypass} do
      {:ok, idp} = Shin.idp(idp_endpoint_url(bypass.port), retries: 0)
      assert_raise RuntimeError,
                   "Could not reload service whatever_resolver: Cannot find service whatever_resolver in list of IdP's reloadable services!",
                   fn ->
                     Service.reload!(idp, :whatever_resolver)
                   end

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
               Service.reload(idp, "shibboleth.MetadataResolverService")
    end

    test "cannot be passed a base URL for the IdP", %{bypass: bypass} do

      idp_url = idp_endpoint_url(bypass.port)
      assert_raise RuntimeError, "IdP record is required", fn ->
        Service.reload!(idp_url, :frying_party_resolver)
      end
      
    end

  end


  defp idp_endpoint_url(port), do: "http://localhost:#{port}/idp"


end
