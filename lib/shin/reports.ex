defmodule Shin.Reports do

  @report_mods %{
    system_info: Shin.Reports.SystemInfo,
    idp_info: Shin.Reports.IdPInfo
  }

  def reporters do
    @report_mods
  end

  def system(idp, metrics) do
    produce(metrics, Shin.Reports.SystemInfo)
  end

  def idp(metrics) do
    produce(metrics, Shin.Reports.IdPInfo)
  end

  def produce(metrics, reporter) do
    with {:ok, reporter} <- normalise_reporter(reporter),
         {:ok, metrics} <- check_metrics(metrics, reporter) do
      {:ok, reporter.produce(metrics)}
    else
      err -> err
    end
  end

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

  defp check_metrics(metrics, reporter) do
    {:ok, metrics}
  end

end
