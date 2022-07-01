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
  x

  y

  ## Examples

    ```
    z
    ```

  """
  @spec reporters() :: map()
  def reporters do
    @report_mods
  end

  @doc """
  x

  y

  ## Examples

    ```
    z
    ```

  """
  @spec reporter_aliases() :: list()
  def reporter_aliases do
    Map.keys(@report_mods)
  end

  @doc """
  x

  y

  ## Examples

    ```
    z
    ```

  """
  @spec reporter_modules() :: list()
  def reporter_modules do
    Map.values(@report_mods)
  end

  @doc """
  x

  y

  ## Examples

    ```
    z
    ```

  """
  @spec system(data :: map()) :: {:ok, struct()} | {:error, binary}
  def system(metrics) do
    produce(metrics, Shin.Reports.SystemInfo)
  end

  @doc """
  x

  y

  ## Examples

    ```
    z
    ```

  """
  @spec idp(data :: map()) :: {:ok, struct()} | {:error, binary}
  def idp(metrics) do
    produce(metrics, Shin.Reports.IdPInfo)
  end

  @doc """
  x

  y

  ## Examples

    ```
    z
    ```

  """
  @spec produce(data :: map(), reporter :: binary() | atom()) :: {:ok, struct()} | {:error, binary}
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

  @spec check_metrics(data :: map(), reporter :: atom()) :: {:ok, map()} | {:error, binary}
  defp check_metrics(metrics, reporter) do
    {:ok, metrics}
  end

end
