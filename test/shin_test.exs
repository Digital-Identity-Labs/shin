defmodule ShinTest do
  use ExUnit.Case, async: false

  doctest Shin

  alias Shin
  alias Shin.IdP

  setup_all do
    Tesla.Mock.mock_global(
      fn
        %{
          method: :get,
          url: "https://login.localhost.demo.university/idp/profile/admin/reload-service"
        } ->
          %Tesla.Env{status: 200, body: "Configuration reloaded for 'shibboleth.MetadataResolverService'\n"}

        %{
          method: :get,
          url: "https://login-miss.localhost.demo.university/idp/profile/admin/reload-service"
        } ->
          %Tesla.Env{status: 404, body: "Error 404 Page Not Found\n"}

        %{
          method: :get,
          url: "https://login-error.localhost.demo.university/idp/profile/admin/reload-service"
        } ->
          %Tesla.Env{status: 500, body: "Error 500 Guru Meditation\n"}

        %{
          method: :get,
          url: "https://login.localhost.demo.university/idp/profile/admin/metrics"
        } ->
          %Tesla.Env{status: 200, body: MetricsExamples.complete()}

        %{
          method: :get,
          url: "https://login-error.localhost.demo.university/idp/profile/admin/metrics"
        } ->
          %Tesla.Env{status: 500, body: "Error 500\n"}

        %{
          method: :get,
          url: "https://login.localhost.demo.university/idp/profile/admin/metrics/core"
        } ->
          %Tesla.Env{status: 200, body: MetricsExamples.core()}

        %{
          method: :get,
          url: "https://login-error.localhost.demo.university/idp/profile/admin/metrics/core"
        } ->
          %Tesla.Env{status: 500, body: "Error 404 Page Not Found\n"}

      end
    )
    :ok
  end

  {:ok, good_idp} = Shin.idp("https://login.localhost.demo.university/idp")
  @good_idp good_idp

  {:ok, miss_idp} = Shin.idp("https://login-miss.localhost.demo.university/idp")
  @miss_idp miss_idp

  {:ok, error_idp} = Shin.idp("https://login-error.localhost.demo.university/idp")
  @error_idp error_idp

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

    test "will reload an existing and known reloadable service, using the service ID" do
      assert {:ok, "Configuration reloaded for 'shibboleth.MetadataResolverService'"} =
               Shin.reload_service(@good_idp, "shibboleth.MetadataResolverService")
    end

    test "will reload and existing and known reloadable service, using an alias" do
      assert {:ok, "Configuration reloaded for 'shibboleth.MetadataResolverService'"} =
               Shin.reload_service(@good_idp, :metadata_resolver)
    end

    test "will complain if passed an unknown service ID" do
      {:ok, idp} = Shin.idp("https://example.com/idp")
      assert {:error, _} = Shin.reload_service(idp, "shibboleth.BetadataResolverService")
    end

    test "will not complain if a new service ID has been added to the IdP configuration" do
      {:ok, example_idp} = Shin.idp(
        "https://login.localhost.demo.university/idp",
        reloadable_services: %{
          metadata_resolver: "shibboleth.BetadataResolverService"
        }
      )
      assert {:ok, _} = Shin.reload_service(example_idp, "shibboleth.BetadataResolverService")
    end

    test "will complain if passed an unknown alias" do
      assert {:error, _} = Shin.reload_service(@good_idp, :whatever_resolver)
    end

    test "will produce a decent error if URL is not found" do
      assert {:error, _} = Shin.reload_service(@miss_idp, :metadata_resolver)
    end

    test "will produce a decent error if server has error" do
      assert {:error, _} = Shin.reload_service(@error_idp, :metadata_resolver)
    end

    test "can be passed an IdP record (expected)" do
      {:ok, idp} = Shin.idp("https://login.localhost.demo.university/idp")
      assert {:ok, "Configuration reloaded for 'shibboleth.MetadataResolverService'"} =
               Shin.reload_service(idp, "shibboleth.MetadataResolverService")
    end

    test "can be passed a base URL for the IdP" do
      assert {:ok, "Configuration reloaded for 'shibboleth.MetadataResolverService'"} =
               Shin.reload_service("https://login.localhost.demo.university/idp", "shibboleth.MetadataResolverService")
    end

  end

  describe "metrics/1" do

    test "will return a map of raw metrics data if the service is available" do
      assert {
               :ok,
               %{
                 "gauges" => %{
                   "net.shibboleth.idp.version" => %{
                     "value" => "4.2.1"
                   }
                 }
               }
             } = Shin.metrics(@good_idp)
    end

    test "will produce a decent error if service is unavailable" do
      assert {:error, "Error 500"} = Shin.metrics(@error_idp)
    end

    test "can be passed an IdP record (expected)" do
      {:ok, idp} = Shin.idp("https://login.localhost.demo.university/idp")
      assert {:ok, %{"gauges" => _things}} = Shin.metrics(idp)
    end

    test "can be passed a base URL for the IdP" do
      assert {:ok, %{"gauges" => _things}} = Shin.metrics("https://login.localhost.demo.university/idp")
    end

  end

  describe "metrics/2" do

    test "will return a map of a subset of raw metrics data if the service is available and the group is known" do
      assert {
               :ok,
               %{
                 "gauges" => %{
                   "cores.available" => _
                 }
               }
             } = Shin.metrics(@good_idp, :core)
    end

    test "will complain if passed an unknown group" do
      assert {:error, "IdP does not support metric group 'baboon'"} = Shin.metrics(@good_idp, :baboon)
    end

    test "will produce a decent error if service is unavailable" do
      assert {:error, "Error 500"} = Shin.metrics(@error_idp, :core)
    end

    test "can be passed an IdP record (expected)" do
      {:ok, idp} = Shin.idp("https://login.localhost.demo.university/idp")
      assert {:ok, %{"gauges" => _things}} = Shin.metrics(idp, :core)
    end

    test "can be passed a base URL for the IdP" do
      assert {:ok, %{"gauges" => _things}} = Shin.metrics("https://login.localhost.demo.university/idp", :core)
    end

  end

  describe "report/1" do

    test "will return a default struct containing processed metrics (system info)" do
      assert {:ok, %Shin.Reports.SystemInfo{hostname: _}} = Shin.report(@good_idp)
    end

    test "will produce a decent error if service is unavailable" do
      assert {:error, "Error 500"} = Shin.report(@error_idp)
    end

    test "can be passed an IdP record (expected)" do
      {:ok, idp} = Shin.idp("https://login.localhost.demo.university/idp")
      assert {:ok, %Shin.Reports.SystemInfo{hostname: _}} = Shin.report(idp)
    end

    test "can be passed a base URL for the IdP" do
      assert {:ok, %Shin.Reports.SystemInfo{hostname: _}} = Shin.report("https://login.localhost.demo.university/idp")
    end

  end

  describe "report/2" do

    test "will return a struct containing processed metrics as specified by the report Module" do
      assert {:ok, %Shin.Reports.IdPInfo{uptime: _}} = Shin.report(@good_idp, Shin.Reports.IdPInfo)
    end

    test "will return a struct containing processed metrics as specified by the report alias" do
      assert {:ok, %Shin.Reports.SystemInfo{hostname: _}} = Shin.report(@good_idp, :system_info)
    end

    test "will complain if passed an unknown alias" do
      assert {:error, _} = Shin.report(@good_idp, :badgers)
    end

    test "will produce a decent error if service is unavailable" do
      assert {:error, "Error 500"} = Shin.report(@error_idp, :system_info)
    end

    test "can be passed an IdP record (expected)" do
      {:ok, idp} = Shin.idp("https://login.localhost.demo.university/idp")
      assert {:ok, %Shin.Reports.SystemInfo{hostname: _}} = Shin.report(idp, Shin.Reports.SystemInfo)
    end

    test "can be passed a base URL for the IdP" do
      assert {:ok, %Shin.Reports.SystemInfo{hostname: _}} = Shin.report(
               "https://login.localhost.demo.university/idp",
               :system_info
             )
    end

  end


end
