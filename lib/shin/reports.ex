defmodule Shin.Reports do

  @report_mods %{
    system_info: Shin.Reports.SystemInfo,
    idp_info: Shin.Reports.IdPInfo
  }

  @spec reporters() :: map()
  def reporters do
    @report_mods
  end

  @spec reporter_aliases() :: list()
  def reporter_aliases do
    Map.keys(@report_mods)
  end

  @spec reporter_modules() :: list()
  def reporter_modules do
    Map.values(@report_mods)
  end

  @spec system(data :: map()) :: {:ok, struct()} | {:error, binary}
  def system(metrics) do
    produce(metrics, Shin.Reports.SystemInfo)
  end

  @spec idp(data :: map()) :: {:ok, struct()} | {:error, binary}
  def idp(metrics) do
    produce(metrics, Shin.Reports.IdPInfo)
  end

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
