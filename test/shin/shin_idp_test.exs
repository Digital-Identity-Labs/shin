defmodule ShinIdPTest do
  use ExUnit.Case

  alias Shin.IdP

  @default_metric_groups [
    :core,
    :idp,
    :logging,
    :access,
    :metadata,
    :nameid,
    :relyingparty,
    :registry,
    :resolver,
    :filter,
    :cas,
    :bean,
  ]

  @default_reloadable_services %{
    relying_party_resolver: "shibboleth.RelyingPartyResolverService",
    metadata_resolver: "shibboleth.MetadataResolverService",
    attribute_registry: "shibboleth.AttributeRegistryService",
    attribute_resolver: "shibboleth.AttributeResolverService",
    attribute_filter: "shibboleth.AttributeFilterService",
    nameid_generator: "shibboleth.NameIdentifierGenerationService",
    access_control: "shibboleth.ReloadableAccessControlService",
    cas_registry: "shibboleth.ReloadableCASServiceRegistry",
    managed_beans: "shibboleth.ManagedBeanService",
    logging: "shibboleth.LoggingService"
  }

  @service_aliases Map.keys(@default_reloadable_services)
  @service_ids Map.values(@default_reloadable_services)

  describe "configure/1" do

    test "returns an IdP struct if passed a valid URL" do
      assert {:ok, %IdP{}} = IdP.configure("https://indiid.net/idp")
    end

    test "will not accept a bad URL" do
      assert {:error, _} = IdP.configure("htps://example.com/idp")
      assert {:error, _} = IdP.configure("//example.com/idp")
      assert {:error, _} = IdP.configure("example.com/idp")
    end

    test "will not accept a URL with an unfindable hostname" do
      assert {:error, _} = IdP.configure("https://dancing.dancing.newt")
    end

    test "returns an IdP struct with default values that match the defaults on a Shibboleth IdP" do 
      {:ok, idp} = IdP.configure("https://indiid.net/idp")

      assert %IdP{
               metrics_path: "profile/admin/metrics",
               reload_path: "profile/admin/reload-service",
               metric_groups: @default_metric_groups,
               reloadable_services: @default_reloadable_services,
               timeout: 2_000,
               retries: 2,
               attributes_path: "profile/admin/resolvertest",
               md_query_path: "profile/admin/mdquery",
               md_reload_path: "profile/admin/reload-metadata",
               lockout_path: "profile/admin/lockout",
               lockout_bean: "shibboleth.StorageBackedAccountLockoutManager"
             } = idp

    end

  end

  describe "configure/2" do

    test "returns an IdP struct if passed a valid URL" do
      assert {:ok, %IdP{}} = IdP.configure("https://indiid.net/idp", [])
    end

    test "will not accept a bad URL" do
      assert {:error, _} = IdP.configure("htps://example.com/idp", [])
      assert {:error, _} = IdP.configure("//example.com/idp", [])
      assert {:error, _} = IdP.configure("example.com/idp", [])
    end

    test "will not normally accept a URL with unfindable hostname" do
      assert {:error, _} = IdP.configure("https://dancing.dancing.newt", [])
    end

    test "will allow an unfindable hostname if the :no_dns_check option is set to true" do
      assert {:error, _} = Shin.idp("htps://indiid.net/idp", no_dns_check: true)
    end

    test "returns an IdP struct with default values that match the defaults on a Shibboleth IdP" do
      {:ok, idp} = IdP.configure("https://indiid.net/idp", [])

      assert %IdP{
               metrics_path: "profile/admin/metrics",
               reload_path: "profile/admin/reload-service",
               metric_groups: @default_metric_groups,
               reloadable_services: @default_reloadable_services,
               timeout: 2_000,
               retries: 2,
               attributes_path: "profile/admin/resolvertest",
               md_query_path: "profile/admin/mdquery",
               md_reload_path: "profile/admin/reload-metadata",
               lockout_path: "profile/admin/lockout",
               lockout_bean: "shibboleth.StorageBackedAccountLockoutManager"
             } = idp

    end

    test "returns an IdP with any options set as attributes" do
      {:ok, idp} = Shin.idp(
        "https://indiid.net/idp",
        [
          metrics_path: "profile/admin2/metrics",
          reload_path: "profile/admin3/reload-service",
          metric_groups: [:baboon, :wombat],
          reloadable_services: %{
            birthday_party_resolver: "shibboleth.BirthdayPartyResolverService"
          },
          timeout: 4_000,
          retries: 0,
          attributes_path: "profile/admin3/resolvertest",
          md_query_path: "profile/admin3/mdquery",
          md_reload_path: "profile/admin3/reload-metadata",
          lockout_path: "profile/admin3/lockout",
          lockout_bean: "shibboleth.SausageRollBackedAccountLockoutManager"
        ]
      )

      assert %IdP{
               metrics_path: "profile/admin2/metrics",
               reload_path: "profile/admin3/reload-service",
               metric_groups: [:baboon, :wombat],
               reloadable_services: %{
                 birthday_party_resolver: "shibboleth.BirthdayPartyResolverService"
               },
               timeout: 4_000,
               retries: 0,
               attributes_path: "profile/admin3/resolvertest",
               md_query_path: "profile/admin3/mdquery",
               md_reload_path: "profile/admin3/reload-metadata",
               lockout_path: "profile/admin3/lockout",
               lockout_bean: "shibboleth.SausageRollBackedAccountLockoutManager"
             } = idp

    end

  end

  describe "metric_groups/1" do

    test "by default returns the default metric groups of a Shibboleth IdP" do

      {:ok, idp} = IdP.configure("https://indiid.net/idp")
      assert @default_metric_groups = IdP.metric_groups(idp)
    end

    test "returns customised lists of metric groups" do
      {:ok, idp} = IdP.configure("https://indiid.net/idp", [metric_groups: [:idp, :vcs]])
      assert [:idp, :vcs] = IdP.metric_groups(idp)
    end

  end

  describe "service_ids/1" do

    test "by default returns the default service_ids of a Shibboleth IdP" do
      {:ok, idp} = IdP.configure("https://indiid.net/idp")
      assert @service_ids = IdP.service_ids(idp)
    end

    test "return a customised list of Service IDs if one has been configured for the IdP" do
      {:ok, idp} = IdP.configure(
        "https://indiid.net/idp",
        reloadable_services: %{
          birthday_party_resolver: "shibboleth.BirthdayPartyResolverService"
        }
      )
      assert ["shibboleth.BirthdayPartyResolverService"] = IdP.service_ids(idp)
    end

  end

  describe "service_aliases/1" do

    test "by default returns the default service_aliases of a Shibboleth IdP" do
      {:ok, idp} = IdP.configure("https://indiid.net/idp")
      assert  @service_aliases = IdP.service_aliases(idp)
    end

    test "return a customised list of service aliases if one has been configured for the IdP" do
      {:ok, idp} = IdP.configure(
        "https://indiid.net/idp",
        reloadable_services: %{
          birthday_party_resolver: "shibboleth.BirthdayPartyResolverService"
        }
      )
      assert [:birthday_party_resolver] = IdP.service_aliases(idp)
    end
  end

  describe "is_reloadable?/2" do

    test "returns true if a service_id is reloadable (really it just checks if it's known)" do
      {:ok, idp} = IdP.configure("https://indiid.net/idp")
      assert true == IdP.is_reloadable?(idp, "shibboleth.AttributeFilterService")
    end

    test "returns true if a service alias is reloadable (really it just checks if it's known)" do
      {:ok, idp} = IdP.configure("https://indiid.net/idp")
      assert true == IdP.is_reloadable?(idp, :attribute_filter)
    end

    test "returns false if a service_id is unknown" do
      {:ok, idp} = IdP.configure("https://indiid.net/idp")
      assert false == IdP.is_reloadable?(idp, "shibboleth.HattributeFilterService")
    end

    test "returns false if a service alias is unknown " do
      {:ok, idp} = IdP.configure("https://indiid.net/idp")
      assert false == IdP.is_reloadable?(idp, :baboons)
    end

  end

  describe "validate_service/2" do

    test "returns a normalised service id if a service_id is acceptable" do
      {:ok, idp} = IdP.configure("https://indiid.net/idp")
      assert {:ok, "shibboleth.AttributeFilterService"} = IdP.validate_service(idp, "shibboleth.AttributeFilterService")
    end

    test "returns a normalised service id if a service alias is acceptable" do
      {:ok, idp} = IdP.configure("https://indiid.net/idp")
      assert {:ok, "shibboleth.AttributeFilterService"} = IdP.validate_service(idp, :attribute_filter)
    end

    test "returns an error if a service_id is unknown" do
      {:ok, idp} = IdP.configure("https://indiid.net/idp")
      assert {:error, _} = IdP.validate_service(idp, "shibboleth.BattributeFilterService")
    end

    test "returns an error if a service alias is unknown " do
      {:ok, idp} = IdP.configure("https://indiid.net/idp")
      assert {:error, _} = IdP.validate_service(idp, :baboons)
    end

  end

  describe "validate_metric_group/2" do

    test "returns a normalised metric group atom if an atom is acceptable" do
      {:ok, idp} = IdP.configure("https://indiid.net/idp")
      assert {:ok, :logging} = IdP.validate_metric_group(idp, :logging)
    end

    test "returns a normalised metric group atom if a string is acceptable" do
      {:ok, idp} = IdP.configure("https://indiid.net/idp")
      assert {:ok, :logging} = IdP.validate_metric_group(idp, "logging")
    end

    test "returns an error if a metric group name atom is unknown" do
      {:ok, idp} = IdP.configure("https://indiid.net/idp")
      assert {:error, _} = IdP.validate_metric_group(idp, :blogging)
    end

    test "returns an error if a binary string metric group name is unknown " do
      {:ok, idp} = IdP.configure("https://indiid.net/idp")
      assert {:error, _} = IdP.validate_metric_group(idp, "blogging")
    end

  end

  describe "metrics_path/1" do

    test "returns the metrics path of the idp" do
      {:ok, idp} = IdP.configure("https://indiid.net/idp", metrics_path: "special/example/path")
      "special/example/path" = IdP.metrics_path(idp)
    end

  end

  describe "metrics_path/2" do

    test "returns the metrics path of the idp, with the metrics group appended to it" do
      {:ok, idp} = IdP.configure("https://indiid.net/idp", metrics_path: "special/example/path")
      "special/example/path/group" = IdP.metrics_path(idp, :group)
    end

  end

end
