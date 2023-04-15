defmodule ShinAttributesTest do
  use ExUnit.Case

  alias Shin.IdP
  alias Shin.Attributes

  @query_results AttributesExamples.basic_json()

  setup do
    bypass = Bypass.open()
    {:ok, bypass: bypass}
  end


  describe "query/4" do

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

      assert {:ok, %{"requester" => "https://test.ukfederation.org.uk/entity"}} = Attributes.query(
               idp,
               "https://test.ukfederation.org.uk/entity",
               "pete"
             )

    end

    test "responds with an error if passed a URL for the IdP",
         %{bypass: bypass} do

      url = idp_endpoint_url(bypass.port)

      assert {:error, "IdP record is required"} = Attributes.query(
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

      assert {:ok, %{"requester" => "https://test.ukfederation.org.uk/entity"}} = Attributes.query(
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

      assert {:ok, %{"principal" => "pete"}} = Attributes.query(
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
      assert {:ok, %{"requester" => "https://test.ukfederation.org.uk/entity"}} = Attributes.query(
               idp,
               "https://test.ukfederation.org.uk/entity",
               "pete"
             )
    end

  end

  describe "query!/4" do

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

      assert %{"requester" => "https://test.ukfederation.org.uk/entity"} = Attributes.query!(
               idp,
               "https://test.ukfederation.org.uk/entity",
               "pete"
             )

    end

    test "responds with an error if passed a URL for the IdP",
         %{bypass: bypass} do

      url = idp_endpoint_url(bypass.port)

      assert_raise RuntimeError, "IdP record is required", fn ->
        Attributes.query!(
          url,
          "https://test.ukfederation.org.uk/entity",
          "pete"
        )
      end

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

      assert  %{"requester" => "https://test.ukfederation.org.uk/entity"} = Attributes.query!(
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

      assert  %{"principal" => "pete"} = Attributes.query!(
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
      assert %{"requester" => "https://test.ukfederation.org.uk/entity"} = Attributes.query!(
               idp,
               "https://test.ukfederation.org.uk/entity",
               "pete"
             )
    end



  end

  describe "principal/1" do

    test "returns the principal from attribute query results" do
      assert "pete" = Attributes.principal(@query_results)
    end

  end

  describe "username/1" do

    test "returns the principal from attribute query results" do
      assert "pete" = Attributes.username(@query_results)
    end

  end

  describe "requester/1" do

    test "returns the SP entity ID from attribute query results" do
      assert "https://test.ukfederation.org.uk/entity" = Attributes.requester(@query_results)
    end

  end

  describe "sp/1" do

    test "returns the SP entity ID from attribute query results" do
      assert "https://test.ukfederation.org.uk/entity" = Attributes.sp(@query_results)
    end

  end

  describe "attributes/1" do

    test "returns a map of attributes (friendly-name to values) taken from attribute query results" do
      assert %{
               "eduPersonEntitlement" => [
                 "urn:mace:dir:entitlement:common-lib-terms",
                 "https://idp.example.ac.uk/dir/ent/stationery_cupboard_access"
               ],
               "eduPersonPrincipalName" => ["pete@example.ac.uk"],
               "eduPersonScopedAffiliation" => ["member@example.ac.uk", "staff@example.ac.uk", "alum@example.ac.uk"],
               "eduPersonUniqueID" => ["pete@example.ac.uk"],
               "o" => ["Example University"]
             } = Attributes.attributes(@query_results)
    end

  end

  describe "names/1" do

    test "lists the friendly names of all attributes" do
      assert [
               "eduPersonEntitlement",
               "eduPersonPrincipalName",
               "eduPersonScopedAffiliation",
               "eduPersonUniqueID",
               "o"
             ] = Attributes.names(@query_results)
    end

  end

  describe "values/2" do

    test "lists the values of the specified attribute" do
      assert  ["member@example.ac.uk", "staff@example.ac.uk", "alum@example.ac.uk"] = Attributes.values(
                @query_results,
                "eduPersonScopedAffiliation"
              )
    end

    test "lookup of the specified attribute should be case-insensitive" do
      assert  ["member@example.ac.uk", "staff@example.ac.uk", "alum@example.ac.uk"] = Attributes.values(
                @query_results,
                "edupersonscopedaffiliation"
              )
      assert  ["member@example.ac.uk", "staff@example.ac.uk", "alum@example.ac.uk"] = Attributes.values(
                @query_results,
                "EDUPERSONSCOPEDAFFILIATION"
              )
    end

  end

  defp idp_endpoint_url(port), do: "http://localhost:#{port}/idp"

end
