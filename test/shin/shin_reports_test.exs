defmodule ShinReportsTest do
  use ExUnit.Case

  alias Shin.Reports

  @big_metrics MetricsExamples.complete()


  describe "reporters/0" do

    test "returns map of reporter aliases and reporter modules" do
      assert %{
               system_info: Shin.Reports.SystemInfo,
               idp_info: Shin.Reports.IdPInfo
             } = Reports.reporters()
    end

  end

  describe "system/1" do

    test "returns SystemInfo structure containing parsed metrics" do
      {:ok, %Reports.SystemInfo{cores: 4}} = Reports.system(@big_metrics)
    end

  end

  describe "idp/1" do
    test "returns IdPInfo structure containing parsed metrics" do
      {:ok, %Reports.IdPInfo{idp_version: "4.2.1"}} = Reports.idp(@big_metrics)
    end
  end

  describe "produce/2" do

    test "returns a report specified using the reporter alias" do
      assert {:ok, %Shin.Reports.SystemInfo{hostname: _}} = Reports.produce(@big_metrics, :system_info)
    end

    test "returns a report specified using the reporter module" do
      assert {:ok, %Reports.IdPInfo{uptime: _}} = Reports.produce(@big_metrics, Shin.Reports.IdPInfo)
    end

    test "will complain if passed an unknown alias" do
      assert {:error, _} = Reports.produce(@big_metrics, :badgers)
    end

    test "will complain if passed an unknown module" do
      assert {:error, _} = Reports.produce(@big_metrics, Shin.Reports.DoesNotExist)
    end

  end

end
