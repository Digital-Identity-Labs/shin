defmodule ShinHTTPTest do
  use ExUnit.Case, async: false

  alias Shin.HTTP


  setup do
    bypass = Bypass.open()
    {:ok, bypass: bypass}
  end

  #  setup_all do
  #    Tesla.Mock.mock_global(
  #      fn
  #        %{
  #          method: :get,
  #          url: "https://login.localhost.demo.university/example/some/json"
  #        } ->
  #          %Tesla.Env{status: 200, body: MetricsExamples.generic}
  #
  #        %{
  #          method: :get,
  #          url: "https://login.localhost.demo.university/example/profile/admin/reload-service"
  #        } ->
  #          %Tesla.Env{status: 200, body: "Sir Morris, not the finest swordsman in the world but the most enthusiastic!"}
  #
  #        %{
  #          method: :get,
  #          url: "https://login-miss.localhost.demo.university/idp/profile/admin/reload-service"
  #        } ->
  #          %Tesla.Env{status: 404, body: "Error 404\n"}
  #
  #        %{
  #          method: :get,
  #          url: "https://login-error.localhost.demo.university/idp/profile/admin/reload-service"
  #        } ->
  #          %Tesla.Env{status: 500, body: "Error 500\n"}
  #
  #        %{
  #          method: :get,
  #          url: "https://login-miss.localhost.demo.university/idp/profile/admin/metrics"
  #        } ->
  #          %Tesla.Env{status: 404, body: "Error 404\n"}
  #
  #        %{
  #          method: :get,
  #          url: "https://login-error.localhost.demo.university/idp/profile/admin/metrics"
  #        } ->
  #          %Tesla.Env{status: 500, body: "Error 500\n"}
  #
  #      end
  #    )
  #    :ok
  #  end

  describe "get_data/4" do


    test "must be passed an IdP record (expected)", %{bypass: bypass} do

      Bypass.expect_once(
        bypass,
        "GET",
        "/example/update.json",
        fn conn ->
          Plug.Conn.resp(conn, 200, File.read!("test/support/star_destroyer.json"))
        end
      )

      {:ok, idp} = Shin.idp(endpoint_url(bypass.port))
      assert {:ok, _metrics} = HTTP.get_data(idp, "/example/update.json")
    end

    test "will raise an error if passed a URL or anything other than an IdP struct" do
      assert_raise RuntimeError, "Shin.HTTP client requires a Shin.IdP struct as the first parameter!", fn ->
        HTTP.get_data("https://login.localhost.demo.university/example", "some/json")
      end
    end

    test "returns a map when reading complex JSON data from an available URL", %{bypass: bypass} do

      Bypass.expect_once(
        bypass,
        "GET",
        "/example/update.json",
        fn conn ->
          Plug.Conn.resp(conn, 200, File.read!("test/support/star_destroyer.json"))
          |> Plug.Conn.merge_resp_headers([{"content-type", "application/json"}])
        end
      )

      {:ok, idp} = Shin.idp(endpoint_url(bypass.port))
      assert {
               :ok,
               %{
                 "starship" => %{
                   "name" => "Star Destroyer"
                 }
               }
             } = HTTP.get_data(idp, "/example/update.json")
    end

    test "returns a string when reading plain text data from an available URL", %{bypass: bypass} do

      Bypass.expect_once(
        bypass,
        "GET",
        "/example/update.txt",
        fn conn ->
          Plug.Conn.resp(conn, 200, "The capybara are restless")
          |> Plug.Conn.merge_resp_headers([{"content-type", "text/plain"}])
        end
      )


      {:ok, idp} = Shin.idp(endpoint_url(bypass.port))
      assert {
               :ok,
               "The capybara are restless"
             } = HTTP.get_data(idp, "/example/update.txt")

    end

    test "returns an error mentioning 404 if URL is not found", %{bypass: bypass} do

      Bypass.expect_once(
        bypass,
        "GET",
        "/example/update.txt",
        fn conn ->
          Plug.Conn.resp(conn, 200, "The capybara are restless")
          |> Plug.Conn.merge_resp_headers([{"content-type", "text/plain"}])
        end
      )

      {:ok, idp} = Shin.idp(endpoint_url(bypass.port))
      assert {
               :ok,
               "The capybara are restless"
             } = HTTP.get_data(idp, "/example/update.txt")

    end

    test "returns an error mentioning 500 if server fails (with retries)", %{bypass: bypass} do

      Bypass.expect(
        bypass,
        "GET",
        "/example/update.txt",
        fn conn ->
          Plug.Conn.resp(conn, 500, "A fake error has occurred")
          |> Plug.Conn.merge_resp_headers([{"content-type", "text/plain"}])
        end
      )

      {:ok, idp} = Shin.idp(endpoint_url(bypass.port))
      assert {
               :error,
               "Error 500"
             } = HTTP.get_data(idp, "/example/update.txt")

    end

    test "returns an error mentioning 500 if server fails, without retries if retries is set to 0", %{bypass: bypass} do

      Bypass.expect_once(
        bypass,
        "GET",
        "/example/update.txt",
        fn conn ->
          Plug.Conn.resp(conn, 500, "A fake error has occurred")
          |> Plug.Conn.merge_resp_headers([{"content-type", "text/plain"}])
        end
      )

      {:ok, idp} = Shin.idp(endpoint_url(bypass.port), retries: 0)
      assert {
               :error,
               "Error 500"
             } = HTTP.get_data(idp, "/example/update.txt")

    end

    test "sets the user agent to be Shin name plus version", %{bypass: bypass} do

      Bypass.expect_once(
        bypass,
        "GET",
        "/example/update.txt",
        fn conn ->

          assert ["Shin 0.2.0"] = Plug.Conn.get_req_header(conn, "user-agent")

          Plug.Conn.resp(conn, 200, "We're fine. We're all fine here now, thank you. How are you?")
          |> Plug.Conn.merge_resp_headers([{"content-type", "text/plain"}])
        end
      )

      {:ok, idp} = Shin.idp(endpoint_url(bypass.port), retries: 0)
      HTTP.get_data(idp, "/example/update.txt")

    end

    test "by default sets header saying it accepts anything", %{bypass: bypass} do

      Bypass.expect_once(
        bypass,
        "GET",
        "/example/update.txt",
        fn conn ->

          assert ["*/*"] = Plug.Conn.get_req_header(conn, "accept")

          Plug.Conn.resp(conn, 200, "We're fine. We're all fine here now, thank you. How are you?")
          |> Plug.Conn.merge_resp_headers([{"content-type", "text/plain"}])
        end
      )

      {:ok, idp} = Shin.idp(endpoint_url(bypass.port), retries: 0)
      HTTP.get_data(idp, "/example/update.txt")

    end

    test "Can request SAML assertion if passed type of :saml2", %{bypass: bypass} do
      Bypass.expect_once(
        bypass,
        "GET",
        "/example/update.txt",
        fn conn ->

          assert ["application/samlassertion+xml"] = Plug.Conn.get_req_header(conn, "accept")

          Plug.Conn.resp(conn, 200, "We're fine. We're all fine here now, thank you. How are you?")
          |> Plug.Conn.merge_resp_headers([{"content-type", "text/plain"}])
        end
      )

      {:ok, idp} = Shin.idp(endpoint_url(bypass.port), retries: 0)
      HTTP.get_data(idp, "/example/update.txt", [], type: :saml2)
    end

    test "Can request SAML metadata if passed type of :saml_md", %{bypass: bypass} do
      Bypass.expect_once(
        bypass,
        "GET",
        "/example/update.txt",
        fn conn ->

          assert ["application/samlmetadata+xml"] = Plug.Conn.get_req_header(conn, "accept")

          Plug.Conn.resp(conn, 200, "We're fine. We're all fine here now, thank you. How are you?")
          |> Plug.Conn.merge_resp_headers([{"content-type", "text/plain"}])
        end
      )

      {:ok, idp} = Shin.idp(endpoint_url(bypass.port), retries: 0)
      HTTP.get_data(idp, "/example/update.txt", [], type: :saml_md)
    end

    test "Can request JSON if passed type of :json", %{bypass: bypass} do
      Bypass.expect_once(
        bypass,
        "GET",
        "/example/update.txt",
        fn conn ->

          assert ["application/json"] = Plug.Conn.get_req_header(conn, "accept")

          Plug.Conn.resp(conn, 200, "We're fine. We're all fine here now, thank you. How are you?")
          |> Plug.Conn.merge_resp_headers([{"content-type", "text/plain"}])
        end
      )

      {:ok, idp} = Shin.idp(endpoint_url(bypass.port), retries: 0)
      HTTP.get_data(idp, "/example/update.txt", [], type: :json)
    end

    test "Can request plain text if passed type of :text or :txt", %{bypass: bypass} do
      Bypass.expect(
        bypass,
        "GET",
        "/example/update.txt",
        fn conn ->

          assert ["text/plain"] = Plug.Conn.get_req_header(conn, "accept")

          Plug.Conn.resp(conn, 200, "We're fine. We're all fine here now, thank you. How are you?")
          |> Plug.Conn.merge_resp_headers([{"content-type", "text/plain"}])
        end
      )

      {:ok, idp} = Shin.idp(endpoint_url(bypass.port), retries: 0)
      HTTP.get_data(idp, "/example/update.txt", [], type: :text)
      HTTP.get_data(idp, "/example/update.txt", [], type: :txt)

    end

  end

  describe "post_data/4" do



  end

  describe "del_data/4" do


  end

  defp endpoint_url(port), do: "http://localhost:#{port}/"

end
