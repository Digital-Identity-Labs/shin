defmodule ShinHTTPTest do
  use ExUnit.Case, async: false

  alias Shin.HTTP

  setup_all do
    Tesla.Mock.mock_global(
      fn
        %{
          method: :get,
          url: "https://login.localhost.demo.university/example/some/json"
        } ->
          %Tesla.Env{status: 200, body: MetricsExamples.generic}

        %{
          method: :get,
          url: "https://login.localhost.demo.university/example/profile/admin/reload-service"
        } ->
          %Tesla.Env{status: 200, body: "Sir Morris, not the finest swordsman in the world but the most enthusiastic!"}

        %{
          method: :get,
          url: "https://login-miss.localhost.demo.university/idp/profile/admin/reload-service"
        } ->
          %Tesla.Env{status: 404, body: "Error 404\n"}

        %{
          method: :get,
          url: "https://login-error.localhost.demo.university/idp/profile/admin/reload-service"
        } ->
          %Tesla.Env{status: 500, body: "Error 500\n"}

        %{
          method: :get,
          url: "https://login-miss.localhost.demo.university/idp/profile/admin/metrics"
        } ->
          %Tesla.Env{status: 404, body: "Error 404\n"}

        %{
          method: :get,
          url: "https://login-error.localhost.demo.university/idp/profile/admin/metrics"
        } ->
          %Tesla.Env{status: 500, body: "Error 500\n"}

      end
    )
    :ok
  end

  describe "get_json/2" do

    test "must be passed an IdP record (expected)" do
      {:ok, idp} = Shin.idp("https://login.localhost.demo.university/example")
      assert {:ok, _metrics} = HTTP.get_json(idp, "some/json")
    end

    test "will raise an error if passed a URL or anything other than an IdP struct" do
      assert_raise RuntimeError, "Shin.HTTP client requires a Shin.IdP struct as the first parameter!", fn ->
        HTTP.get_json("https://login.localhost.demo.university/example", "some/json")
      end
    end

    test "returns a map when reading complex JSON data from an available URL" do
      {:ok, idp} = Shin.idp("https://login.localhost.demo.university/example")
      assert {:ok, %{"starship" => %{"name" => "Star Destroyer"}}} = HTTP.get_json(idp, "some/json")
    end

    test "returns an error mentioning 404 if URL is not found" do
      {:ok, idp} = Shin.idp("https://login-miss.localhost.demo.university/idp")
      assert {:error, "Error 404"} = HTTP.get_json(idp, "profile/admin/metrics")
    end

    test "returns an error mentioning 500 if server fails" do
      {:ok, idp} = Shin.idp("https://login-error.localhost.demo.university/idp")
      assert {:error, "Error 500"} = HTTP.get_json(idp, "profile/admin/metrics")
    end

  end

  describe "get_reload/2" do

    test "must be passed an IdP record (expected)" do
      {:ok, idp} = Shin.idp("https://login.localhost.demo.university/example")
      assert {:ok, _message} = HTTP.get_reload(idp, "some/text")
    end

    test "will raise an error if passed a URL or anything other than an IdP struct" do
      assert_raise RuntimeError, "Shin.HTTP client requires a Shin.IdP struct as the first parameter!", fn ->
        HTTP.get_reload("https://login.localhost.demo.university/example", "morris")
      end
    end

    test "returns a string when reading complex JSON data from an available URL" do
      {:ok, idp} = Shin.idp("https://login.localhost.demo.university/example")
      assert {:ok, "Sir Morris, not the finest swordsman in the world but the most enthusiastic!"} = HTTP.get_reload(idp, "morris")
    end

    test "returns an error mentioning 404 if URL is not found" do
      {:ok, idp} = Shin.idp("https://login-miss.localhost.demo.university/idp")
      assert {:error, "Error 404"} =  HTTP.get_reload(idp, "morris")
    end

    test "returns an error mentioning 500 if server fails" do
      {:ok, idp} = Shin.idp("https://login-error.localhost.demo.university/idp")
      assert {:error, "Error 500"} =  HTTP.get_reload(idp, "morris")
    end

  end


end
