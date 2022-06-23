defmodule ShinTest do
  use ExUnit.Case
  doctest Shin

  alias Shin
  alias Shin.IdP

  describe "idp/2" do

    test "Returns an IdP struct if passed a valid URL, without options" do
      assert {:ok, %IdP{}} = Shin.idp("https://indiid.net/idp")
    end

  end

  describe "reload_service/2" do

  end

  describe "metrics/1" do

  end

  describe "metrics/2" do

  end

  describe "report/1" do

  end

  describe "report/2" do

  end


end
