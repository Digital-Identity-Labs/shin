defmodule Shin.Reports do

  @moduledoc """
    This module contains functions for converting the metrics data returned from a Shibboleth IdP into
    simplified maps of data.
  """

  @report_mods %{
    system_info: Shin.Reports.SystemInfo,
    idp_info: Shin.Reports.IdPInfo
  }

  @doc """
  Returns a map of reporter aliases and modules.

  ## Examples

    ```
    Shin.Reports.reporters
    # => %{system_info: Shin.Reports.SystemInfo, idp_info: Shin.Reports.IdPInfo}
    ```

  """
  @spec reporters() :: map()
  def reporters do
    @report_mods
  end

  @doc """
  Returns a list reporter aliases

  ## Examples

    ```
    Shin.Reports.reporter_aliases
    # => [:system_info, :idp_info]
    ```

  """
  @spec reporter_aliases() :: list()
  def reporter_aliases do
    Map.keys(@report_mods)
  end

  @doc """
  Returns a map of reporter modules.

  ## Examples

    ```
    Shin.Reports.reporter_modules
    # => [Shin.Reports.SystemInfo, Shin.Reports.IdPInfo]
    ```

  """
  @spec reporter_modules() :: list()
  def reporter_modules do
    Map.values(@report_mods)
  end

  @doc """
  A convenience function to produce a SystemInfo report (reformated "core" metrics)

  ## Examples

    ```
    Shin.Reports.system(metrics)
    # => {:ok, %Reports.SystemInfo{cores: 4,  ...}}
    ```

  """
  @spec system(metrics :: map()) :: {:ok, struct()} | {:error, binary}
  def system(metrics) do
    produce(metrics, Shin.Reports.SystemInfo)
  end

  @doc """
  A convenience function to produce a IdPInfo report (reformated "idp" metrics)

  ## Examples

    ```
    Shin.Reports.idp(metrics)
    # => {:ok, %Reports.IdPInfo{ ... }}
    ```

  """
  @spec idp(metrics :: map()) :: {:ok, struct()} | {:error, binary}
  def idp(metrics) do
    produce(metrics, Shin.Reports.IdPInfo)
  end

  @doc """
  Produce the specified report using the provided metrics

  The reporter can be an alias (an atom already know to Shin) or any suitable module.

  ## Examples

    ```
    Reports.produce(metrics, :system_info)
    # => {:ok, %Shin.Reports.SystemInfo{ ... }}

    Reports.produce(metrics, Shin.Reports.IdPInfo)
    # => {:ok, %Reports.IdPInfo{ ... }}
    ```

  """
  @spec produce(metrics :: map(), reporter :: binary() | atom()) :: {:ok, struct()} | {:error, binary}
  def produce(metrics, reporter) do
    with {:ok, reporter} <- normalise_reporter(reporter),
         {:ok, metrics} <- check_metrics(metrics, reporter) do
      {:ok, reporter.produce(metrics)}
    else
      err -> err
    end
  end

  @spec normalise_reporter(reporter :: atom()) :: {:ok, atom()} | {:error, binary()}
  defp normalise_reporter(reporter) when is_atom(reporter) do
    report_module = Map.get(@report_mods, reporter, nil)
    if report_module do
      {:ok, report_module}
    else
      if function_exported?(reporter, :__info__, 1) do
        {:ok, reporter}
      else
        {:error, "Reporter #{reporter} cannot be found"}
      end
    end
  end

  @spec check_metrics(metrics :: map(), reporter :: atom()) :: {:ok, map()} | {:error, binary}
  defp check_metrics(metrics, reporter) do
    {:ok, metrics}
  end

end
