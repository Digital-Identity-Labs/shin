defmodule ShinTest do
  use ExUnit.Case, async: false

  doctest Shin

  alias Shin
  alias Shin.IdP

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

  # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

  describe "attributes/4" do

    test "if passed an IdP, SP's entity ID, and username/principal, it returns appropriate attributes, etc as a map",
         %{bypass: bypass} do

      Bypass.expect(
        bypass,
        "GET",
        "/idp/profile/admin/resolvertest",
        fn conn ->
          Plug.Conn.resp(conn, 200, AttributesExamples.basic_raw())
          |> Plug.Conn.merge_resp_headers([{"content-type", "application/json"}])
        end
      )

      {:ok, idp} = Shin.idp(idp_endpoint_url(bypass.port))

      assert {:ok, %{"requester" => "https://test.ukfederation.org.uk/entity"}} = Shin.attributes(
               idp,
               "https://test.ukfederation.org.uk/entity",
               "pete"
             )

    end

    test "Is happy if passed a URL for the IdP",
         %{bypass: bypass} do

      Bypass.expect(
        bypass,
        "GET",
        "/idp/profile/admin/resolvertest",
        fn conn ->
          Plug.Conn.resp(conn, 200, AttributesExamples.basic_raw())
          |> Plug.Conn.merge_resp_headers([{"content-type", "application/json"}])
        end
      )

      url = idp_endpoint_url(bypass.port)

      assert {:ok, %{"requester" => "https://test.ukfederation.org.uk/entity"}} = Shin.attributes(
               url,
               "https://test.ukfederation.org.uk/entity",
               "pete"
             )

    end

    test "the results include the target SP's entity ID",
         %{bypass: bypass} do

      Bypass.expect(
        bypass,
        "GET",
        "/idp/profile/admin/resolvertest",
        fn conn ->
          Plug.Conn.resp(conn, 200, AttributesExamples.basic_raw())
          |> Plug.Conn.merge_resp_headers([{"content-type", "application/json"}])
        end
      )

      {:ok, idp} = Shin.idp(idp_endpoint_url(bypass.port))

      assert {:ok, %{"requester" => "https://test.ukfederation.org.uk/entity"}} = Shin.attributes(
               idp,
               "https://test.ukfederation.org.uk/entity",
               "pete"
             )

    end

    test "the results include the username/principal",
         %{bypass: bypass} do

      Bypass.expect(
        bypass,
        "GET",
        "/idp/profile/admin/resolvertest",
        fn conn ->
          Plug.Conn.resp(conn, 200, AttributesExamples.basic_raw())
          |> Plug.Conn.merge_resp_headers([{"content-type", "application/json"}])
        end
      )

      {:ok, idp} = Shin.idp(idp_endpoint_url(bypass.port))

      assert {:ok, %{"principal" => "pete"}} = Shin.attributes(
               idp,
               "https://test.ukfederation.org.uk/entity",
               "pete"
             )

    end

    test "request needs to be using the resolvertest endpoint of the IdP, but with JSON media type",
         %{bypass: bypass} do

      ## Otherwise these tests aren't really testing much other than the mock

      Bypass.expect(
        bypass,
        "GET",
        "/idp/profile/admin/resolvertest",
        fn conn ->

          assert  is_nil(conn.query_params["saml2"])
          assert ["application/json"] = Plug.Conn.get_req_header(conn, "accept")
          assert %{
                   "principal" => "pete",
                   "requester" => "https://test.ukfederation.org.uk/entity",
                 } = conn.query_params

          Plug.Conn.resp(conn, 200, AttributesExamples.basic_raw())
          |> Plug.Conn.merge_resp_headers([{"content-type", "application/json"}])
        end
      )

      {:ok, idp} = Shin.idp(idp_endpoint_url(bypass.port), retries: 0)
      assert {:ok, %{"requester" => "https://test.ukfederation.org.uk/entity"}} = Shin.attributes(
               idp,
               "https://test.ukfederation.org.uk/entity",
               "pete"
             )
    end
  end

  describe "assertion/4" do

    test "if passed an IdP, SP's entity ID, and username, it returns appropriate attributes as a SAML assertion/binary string",
         %{bypass: bypass} do

      Bypass.expect(
        bypass,
        "GET",
        "/idp/profile/admin/resolvertest",
        fn conn ->
          Plug.Conn.resp(conn, 200, AssertionExamples.basic_raw())
          |> Plug.Conn.merge_resp_headers([{"content-type", "application/samlassertion+xml"}])
        end
      )

      {:ok, idp} = Shin.idp(idp_endpoint_url(bypass.port))

      assert {:ok, "<?xml version=\"1.0\" encoding=\"UTF-8\"?><saml2:Assertion" <> _xml} = Shin.assertion(
               idp,
               "https://test.ukfederation.org.uk/entity",
               "pete"
             )

    end

    test "is happy to be passed a URL for the IdP", %{bypass: bypass} do

      Bypass.expect(
        bypass,
        "GET",
        "/idp/profile/admin/resolvertest",
        fn conn ->
          Plug.Conn.resp(conn, 200, AssertionExamples.basic_raw())
          |> Plug.Conn.merge_resp_headers([{"content-type", "application/samlassertion+xml"}])
        end
      )

      url = idp_endpoint_url(bypass.port)

      assert {:ok, "<?xml version=\"1.0\" encoding=\"UTF-8\"?><saml2:Assertion" <> _xml} = Shin.assertion(
               url,
               "https://test.ukfederation.org.uk/entity",
               "pete"
             )
    end

    test "the SAML assertion is SAML2-compliant", %{bypass: bypass} do

      Bypass.expect(
        bypass,
        "GET",
        "/idp/profile/admin/resolvertest",
        fn conn ->
          Plug.Conn.resp(conn, 200, AssertionExamples.basic_raw())
          |> Plug.Conn.merge_resp_headers([{"content-type", "application/samlassertion+xml"}])
        end
      )

      {:ok, idp} = Shin.idp(idp_endpoint_url(bypass.port))

      {:ok, assertion} = Shin.assertion(
        idp,
        "https://test.ukfederation.org.uk/entity",
        "pete"
      )

      assert  "<?xml version=\"1.0\" encoding=\"UTF-8\"?><saml2:Assertion" <> _xml = assertion
      assert  String.contains?(assertion, ~s|Version="2.0"|)
    end

    test "request needs to be using the resolvertest endpoint of the IdP, but with SAML2 option and media type",
         %{bypass: bypass} do

      ## Otherwise these tests aren't really testing much other than the mock

      Bypass.expect(
        bypass,
        "GET",
        "/idp/profile/admin/resolvertest",
        fn conn ->

          assert  "true" = conn.query_params["saml2"]
          assert ["application/samlassertion+xml"] = Plug.Conn.get_req_header(conn, "accept")
          assert %{
                   "principal" => "pete",
                   "requester" => "https://test.ukfederation.org.uk/entity",
                   "saml2" => "true"
                 } = conn.query_params

          Plug.Conn.resp(conn, 200, AssertionExamples.basic_raw())
          |> Plug.Conn.merge_resp_headers([{"content-type", "application/samlassertion+xml"}])
        end
      )

      {:ok, idp} = Shin.idp(idp_endpoint_url(bypass.port), retries: 0)
      assert {:ok, "<?xml version=\"1.0\" encoding=\"UTF-8\"?><saml2:Assertion" <> _xml} = Shin.assertion(
               idp,
               "https://test.ukfederation.org.uk/entity",
               "pete"
             )
    end

  end

  describe "metadata/3" do

    test "if passed an IdP and SP's entity ID it returns whatever metadata the IdP has for that SP",
         %{bypass: bypass} do

      Bypass.expect(
        bypass,
        "GET",
        "/idp/profile/admin/mdquery",
        fn conn ->
          Plug.Conn.resp(conn, 200, MetadataExamples.basic_raw())
          |> Plug.Conn.merge_resp_headers([{"content-type", "application/samlmetadata+xml"}])
        end
      )

      {:ok, idp} = Shin.idp(idp_endpoint_url(bypass.port))

      assert {:ok, "<?xml version=\"1.0\" encoding=\"UTF-8\"?><EntityDescriptor" <> _xml} = Shin.metadata(
               idp,
               "https://test.ukfederation.org.uk/entity"
             )

    end

    test "is fine with getting a URL for the IdP", %{bypass: bypass} do

      Bypass.expect(
        bypass,
        "GET",
        "/idp/profile/admin/mdquery",
        fn conn ->
          Plug.Conn.resp(conn, 200, MetadataExamples.basic_raw())
          |> Plug.Conn.merge_resp_headers([{"content-type", "application/samlmetadata+xml"}])
        end
      )

      url = idp_endpoint_url(bypass.port)

      assert {:ok, "<?xml version=\"1.0\" encoding=\"UTF-8\"?><EntityDescriptor" <> _xml} = Shin.metadata(
               url,
               "https://test.ukfederation.org.uk/entity"
             )
    end

    test "the metadata appears to be a binary containing XML", %{bypass: bypass} do

      Bypass.expect(
        bypass,
        "GET",
        "/idp/profile/admin/mdquery",
        fn conn ->
          Plug.Conn.resp(conn, 200, MetadataExamples.basic_raw())
          |> Plug.Conn.merge_resp_headers([{"content-type", "application/samlmetadata+xml"}])
        end
      )

      {:ok, idp} = Shin.idp(idp_endpoint_url(bypass.port))

      {:ok, assertion} = Shin.metadata(
        idp,
        "https://test.ukfederation.org.uk/entity"
      )

      assert  "<?xml version=\"1.0\" encoding=\"UTF-8\"?><EntityDescriptor" <> _xml = assertion
      assert  String.contains?(assertion, ~s|entityID="https://test.ukfederation.org.uk/entity"|)
    end

    test "request specifies the correct media type, etc",
         %{bypass: bypass} do

      Bypass.expect(
        bypass,
        "GET",
        "/idp/profile/admin/mdquery",
        fn conn ->

          assert ["application/samlmetadata+xml"] = Plug.Conn.get_req_header(conn, "accept")

          assert %{"entityID" => "https://test.ukfederation.org.uk/entity"} = conn.query_params

          Plug.Conn.resp(conn, 200, MetadataExamples.basic_raw())
          |> Plug.Conn.merge_resp_headers([{"content-type", "application/samlmetadata+xml"}])
        end
      )

      {:ok, idp} = Shin.idp(idp_endpoint_url(bypass.port), retries: 0)
      assert {:ok, "<?xml version=\"1.0\" encoding=\"UTF-8\"?><EntityDescriptor" <> _xml} = Shin.metadata(
               idp,
               "https://test.ukfederation.org.uk/entity"
             )
    end
  end

  describe "reload_metadata/3" do

    test "causes the specified metadata provider to reload, if it exists", %{bypass: bypass} do

      Bypass.expect_once(
        bypass,
        "GET",
        "/idp/profile/admin/reload-metadata",
        fn conn ->
          Plug.Conn.resp(conn, 200, "Metadata reloaded for 'exOverride'\n")
        end
      )

      {:ok, idp} = Shin.idp(idp_endpoint_url(bypass.port), retries: 0)
      assert {:ok, "Metadata reloaded for 'exOverride'"} =
               Shin.reload_metadata(idp, "exOverride")

    end

    test "returns an error if the metadata provider does not exist", %{bypass: bypass} do

      Bypass.expect_once(
        bypass,
        "GET",
        "/idp/profile/admin/reload-metadata",
        fn conn ->
          Plug.Conn.resp(conn, 404, "Not found\n")
        end
      )

      {:ok, idp} = Shin.idp(idp_endpoint_url(bypass.port), retries: 0)
      assert {:error, "Metadata reload failed for 'exMissingProvider'"} =
               Shin.reload_metadata(idp, "exMissingProvider")
    end

    test "can accept an IdP as a simple URL binary", %{bypass: bypass} do

      Bypass.expect_once(
        bypass,
        "GET",
        "/idp/profile/admin/reload-metadata",
        fn conn ->
          Plug.Conn.resp(conn, 200, "Metadata reloaded for 'exOverride'\n")
        end
      )

      url = idp_endpoint_url(bypass.port)
      assert {:ok, "Metadata reloaded for 'exOverride'"} =
               Shin.reload_metadata(url, "exOverride")

    end

  end

  describe "service/3" do

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
             } = Shin.service(idp, "shibboleth.RelyingPartyResolverService")
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
             } = Shin.service(idp, :relying_party_resolver)
    end

    test "returns an error tuple if the service is unknown for that IdP", %{bypass: bypass} do
      {:ok, idp} = Shin.idp(idp_endpoint_url(bypass.port), retries: 0)
      assert {:error, _} = Shin.service(idp, :frying_party_resolver)
    end

    test "doesn't mind if the IdP is a string, not a struct", %{bypass: bypass} do

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
      assert {:ok, _} = Shin.service(url, :relying_party_resolver)
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

      assert {:ok, %{ok: true}} = Shin.service(idp, "shibboleth.ReloadableAccessControlService")
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
             } = Shin.service(idp, "shibboleth.RelyingPartyResolverService")
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

      assert {:ok, %{ok: false}} = Shin.service(idp, "shibboleth.LoggingService")

    end
  end


  defp idp_endpoint_url(port), do: "http://localhost:#{port}/idp"

end
