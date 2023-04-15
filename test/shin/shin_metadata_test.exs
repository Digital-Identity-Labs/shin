defmodule ShinMetadataTest do
  use ExUnit.Case

  alias Shin.IdP
  alias Shin.Metadata

  setup do
    bypass = Bypass.open()
    {:ok, bypass: bypass}
  end

  describe "query/3" do

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

      assert {:ok, "<?xml version=\"1.0\" encoding=\"UTF-8\"?><EntityDescriptor" <> _xml} = Metadata.query(
               idp,
               "https://test.ukfederation.org.uk/entity"
             )

    end

    test "responds with an error if passed a URL for the IdP", %{bypass: bypass} do
      url = idp_endpoint_url(bypass.port)

      assert {:error, "IdP record is required"} = Metadata.query(
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

      {:ok, assertion} = Metadata.query(
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
      assert {:ok, "<?xml version=\"1.0\" encoding=\"UTF-8\"?><EntityDescriptor" <> _xml} = Metadata.query(
               idp,
               "https://test.ukfederation.org.uk/entity"
             )
    end

  end

  describe "query!/3" do

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

      assert "<?xml version=\"1.0\" encoding=\"UTF-8\"?><EntityDescriptor" <> _xml = Metadata.query!(
               idp,
               "https://test.ukfederation.org.uk/entity"
             )

    end

    test "raises an exception if passed a URL for the IdP", %{bypass: bypass} do

      url = idp_endpoint_url(bypass.port)

      assert_raise RuntimeError, "IdP record is required", fn ->
        Metadata.query!(
          url,
          "https://test.ukfederation.org.uk/entity"
        )
      end
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

      assertion = Metadata.query!(
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
      assert "<?xml version=\"1.0\" encoding=\"UTF-8\"?><EntityDescriptor" <> _xml = Metadata.query!(
               idp,
               "https://test.ukfederation.org.uk/entity"
             )
    end

  end

  describe "providers/1" do

    test "queries IdP metrics to return a list of active metadata providers", %{bypass: bypass} do

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

      assert ["exBilateral", "exLocal", "exOverride", "ukfMDQ"] = Shin.Metadata.providers(idp)

    end

  end

  describe "reload/3" do

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
               Metadata.reload(idp, "exOverride")

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
               Metadata.reload(idp, "exMissingProvider")
    end


  end

  describe "cache/2" do

    test "causes every entity ID in the provided list to be looked up by the IdP", %{bypass: bypass} do

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

      assert ["https://test.ukfederation.org.uk/entity", "https://indiid.net/idp/shibboleth"] = Metadata.cache(
               idp,
               ["https://test.ukfederation.org.uk/entity", "https://indiid.net/idp/shibboleth"]
             )

    end

    test "only successfully cached entity IDs are returned in the list", %{bypass: bypass} do

      Bypass.expect(
        bypass,
        "GET",
        "/idp/profile/admin/mdquery",
        fn conn ->

          if conn.query_params["entityID"] == "https://test.ukfederation.org.uk/entity" do
            Plug.Conn.resp(conn, 200, MetadataExamples.basic_raw())
            |> Plug.Conn.merge_resp_headers([{"content-type", "application/samlmetadata+xml"}])
          else
            Plug.Conn.resp(conn, 404, "Error")
            |> Plug.Conn.merge_resp_headers([{"content-type", "text/plain"}])
          end
        end
      )

      {:ok, idp} = Shin.idp(idp_endpoint_url(bypass.port))

      assert ["https://test.ukfederation.org.uk/entity"] = Metadata.cache(
               idp,
               ["https://test.ukfederation.org.uk/entity", "https://example.net/unknown"]
             )
    end

    test "can also accept a single entity ID as a binary string", %{bypass: bypass} do
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

      assert ["https://test.ukfederation.org.uk/entity"] = Metadata.cache(
               idp,
               "https://test.ukfederation.org.uk/entity"
             )

    end

  end

  describe "protocols/0" do

    test "lists the available protocols for metadata lookup" do
      assert  [:cas, :saml1, :saml2] = Metadata.protocols()
    end

  end

  defp idp_endpoint_url(port), do: "http://localhost:#{port}/idp"

end
