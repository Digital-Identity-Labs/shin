defmodule ShinAssertionTest do
  use ExUnit.Case

  alias Shin.IdP
  alias Shin.Assertion

  setup do
    bypass = Bypass.open()
    {:ok, bypass: bypass}
  end

  describe "query/4" do

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

      assert {:ok, "<?xml version=\"1.0\" encoding=\"UTF-8\"?><saml2:Assertion" <> _xml} = Assertion.query(
               idp,
               "https://test.ukfederation.org.uk/entity",
               "pete"
             )

    end

    test "responds with an error if passed a URL for the IdP", %{bypass: bypass} do
      url = idp_endpoint_url(bypass.port)

      assert {:error, "IdP record is required"} = Assertion.query(
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

      {:ok, assertion} = Assertion.query(
        idp,
        "https://test.ukfederation.org.uk/entity",
        "pete"
      )

      assert  "<?xml version=\"1.0\" encoding=\"UTF-8\"?><saml2:Assertion" <> _xml = assertion
      assert  String.contains?(assertion, ~s|Version="2.0"|)
    end

    test "request needs to be using the resolver test endpoint of the IdP, but with SAML2 option and media type",
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
      assert {:ok, "<?xml version=\"1.0\" encoding=\"UTF-8\"?><saml2:Assertion" <> _xml} = Assertion.query(
               idp,
               "https://test.ukfederation.org.uk/entity",
               "pete"
             )
    end

  end

  describe "query!/4" do

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

      assert "<?xml version=\"1.0\" encoding=\"UTF-8\"?><saml2:Assertion" <> _xml = Assertion.query!(
               idp,
               "https://test.ukfederation.org.uk/entity",
               "pete"
             )

    end

    test "raises an exception if passed a URL for the IdP", %{bypass: bypass} do
      url = idp_endpoint_url(bypass.port)

      assert_raise RuntimeError, "IdP record is required", fn ->
        Assertion.query!(
          url,
          "https://test.ukfederation.org.uk/entity",
          "pete"
        )
      end

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

      assertion = Assertion.query!(
        idp,
        "https://test.ukfederation.org.uk/entity",
        "pete"
      )

      assert  "<?xml version=\"1.0\" encoding=\"UTF-8\"?><saml2:Assertion" <> _xml = assertion
      assert  String.contains?(assertion, ~s|Version="2.0"|)
    end

    test "request needs to be using the resolver test endpoint of the IdP, but with SAML2 option and media type",
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
      assert "<?xml version=\"1.0\" encoding=\"UTF-8\"?><saml2:Assertion" <> _xml = Assertion.query!(
               idp,
               "https://test.ukfederation.org.uk/entity",
               "pete"
             )
    end

  end


  defp idp_endpoint_url(port), do: "http://localhost:#{port}/idp"


end
