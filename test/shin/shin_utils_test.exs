defmodule ShinUtilsTest do
  use ExUnit.Case

  alias Shin.IdP
  alias Shin.Utils

  setup do
    bypass = Bypass.open()
    {:ok, bypass: bypass}
  end

  describe "named_version/0" do

    test "should contain the name of this library, 'Shin'" do
      assert String.contains?(Utils.named_version(), "Shin")
    end

    test "should contain the version of this library, #{Application.spec(:shin, :vsn)}" do
      assert String.contains?(Utils.named_version(), "#{Application.spec(:shin, :vsn)}")
    end

  end

  describe "wrap_results/1" do

    test "should pass through the :ok value without the tuple" do
      assert "hello" = Utils.wrap_results({:ok, "hello"})
    end

    test "should raise on an error tuple, with the message passed as the exception message" do
      assert_raise RuntimeError, "No cheese, Gromit! Not a bit in the house!", fn ->
        Utils.wrap_results({:error, "No cheese, Gromit! Not a bit in the house!"})
      end
    end

  end
  describe "build_attribute_query/4" do

    test "it should build the correct default params for the Shibboleth IdP resolvertest API in JSON mode",
         %{bypass: bypass} do
      {:ok, idp} = Shin.idp(idp_endpoint_url(bypass.port))
      assert [requester: "https://test.ukfederation.org.uk/entity", principal: "pete"] = Utils.build_attribute_query(
               idp,
               "https://test.ukfederation.org.uk/entity",
               "pete",
               []
             )
    end

    test "acsIndex can be set with an option", %{bypass: bypass} do
      {:ok, idp} = Shin.idp(idp_endpoint_url(bypass.port))
      assert [
               requester: "https://test.ukfederation.org.uk/entity",
               principal: "pete",
               acsIndex: "5"
             ] = Utils.build_attribute_query(
               idp,
               "https://test.ukfederation.org.uk/entity",
               "pete",
               [acs_index: 5]
             )
    end

  end

  describe "build_mdq_query/3" do

    test "it should build the correct default params for the Shibboleth IdP metadata query API", %{bypass: bypass} do
      {:ok, idp} = Shin.idp(idp_endpoint_url(bypass.port))
      assert [entityID: "https://test.ukfederation.org.uk/entity"] = Utils.build_mdq_query(
               idp,
               "https://test.ukfederation.org.uk/entity",
               []
             )
    end

    test "protocol can be set with an option", %{bypass: bypass} do
      {:ok, idp} = Shin.idp(idp_endpoint_url(bypass.port))
      assert [entityID: "https://test.ukfederation.org.uk/entity", protocol: "saml1"] = Utils.build_mdq_query(
               idp,
               "https://test.ukfederation.org.uk/entity",
               [protocol: :saml1]
             )
    end

  end

  describe "build_mdr_query/3" do
    test "it should build the correct default params for the Shibboleth IdP metadata reload API", %{bypass: bypass} do
      {:ok, idp} = Shin.idp(idp_endpoint_url(bypass.port))
      assert [id: "exProvider"] = Utils.build_mdr_query(
               idp,
               "exProvider",
               []
             )
    end
  end

  describe "build_lockout_path/4" do
    test "it should build the correct path for the Shibboleth IdP lockout API", %{bypass: bypass} do
      {:ok, idp} = Shin.idp(idp_endpoint_url(bypass.port))
      assert "profile/admin/lockout/shibboleth.StorageBackedAccountLockoutManager/pete!10.2.2.2" = Utils.build_lockout_path(
               idp,
               "pete",
               "10.2.2.2",
               []
             )
    end
  end

  describe "build_service_reload_query/3" do
    test "it should build the correct default params for the Shibboleth IdP service reload API", %{bypass: bypass} do
      {:ok, idp} = Shin.idp(idp_endpoint_url(bypass.port))
      assert [id: "shibboleth.MetadataResolverService"] = Utils.build_service_reload_query(
               idp,
               "shibboleth.MetadataResolverService",
               []
             )
    end
  end

  defp idp_endpoint_url(port), do: "http://localhost:#{port}/idp"

end
