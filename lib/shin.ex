defmodule Shin do

  alias Shin.IdP
  alias Shin.HTTP
  alias Shin.Metrics
  alias Shin.Reports

  @spec idp(idp :: binary | IdP.t(), opts :: keyword)  :: {:ok, IdP.t()} | {:error, binary}
  def idp(idp, opts \\ []) do
    IdP.configure(idp, opts)
  end

  @spec reload_service(idp :: binary | IdP.t(), service :: atom | binary)  :: {:ok, binary} | {:error, binary}
  def reload_service(idp, service) do
    with {:ok, idp} <- prep_idp(idp),
         {:ok, service} <- IdP.validate_service(idp, service) do
      HTTP.get_reload(idp, service)
    else
      err -> err
    end
  end

  @spec metrics(idp :: binary | IdP.t()) :: {:ok,map()} | {:error, binary}
  def metrics(idp) do
    with {:ok, idp} <- prep_idp(idp) do
      HTTP.get_json(idp, idp.metrics_path)
    else
      err -> err
    end
  end

  @spec metrics(idp :: binary | IdP.t(), group :: atom | binary) :: {:ok,map()} | {:error, binary}
  def metrics(idp, group) do
    with {:ok, idp} <- prep_idp(idp),
         {:ok, group} <- IdP.validate_metric_group(idp, group),
         metrics_path <- IdP.metrics_path(idp, group) do
      HTTP.get_json(idp, metrics_path)
    else
      err -> err
    end
  end

  @spec report(idp :: binary | IdP.t()) :: {:ok, struct()} | {:error, binary}
  def report(idp) do
    report(idp, :system_info)
  end

  @spec report(idp :: binary | IdP.t(), reporter :: atom()) :: {:ok, struct()} | {:error, binary}
  def report(idp, reporter) do
    with {:ok, idp} <- prep_idp(idp),
         {:ok, metrics} <- metrics(idp) do
      Reports.produce(metrics, reporter)
    else
      err -> err
    end
  end

  @spec prep_idp(idp :: binary | IdP.t()) :: {:ok, struct()} | {:error, binary}
  defp prep_idp(idp) when is_binary(idp) do
    IdP.configure(idp)
  end

  defp prep_idp(%IdP{base_url: _} = idp) do
    {:ok, idp}
  end

end
