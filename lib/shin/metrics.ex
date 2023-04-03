defmodule Shin.Metrics do

  @moduledoc """
    This module contains convenient functions for processing the metrics data returned from a Shibboleth IdP.
  """

  alias Shin.HTTP
  alias Shin.IdP

  @doc """
  List the keys for all gauges in the metrics.

  Requires a metrics map as the only parameter.

  ## Examples

    ```
    Shin.Metrics.gauge_ids(metrics)
    # => ["cores.available", "host.name", "java.class.path" ...]
    ```

  """
  @spec gauge_ids(data :: map()) :: list()
  def gauge_ids(%{"gauges" => gauges} = data) do
    Map.keys(gauges)
  end

  @doc """
  Return the value for a gauge.

  Specify the metrics map and key for the value to be extracted (assuming it's in a `value:` field)

  ## Examples

    ```
    Shin.Metrics.gauge(metrics, "cores.available")
    # => 8
    ```

  """
  @spec gauge(data :: map(), gauge :: binary()) :: binary | integer
  def gauge(%{"gauges" => gauges} = data, gauge) do
    Map.get(gauges, gauge, %{})
    |> Map.get("value", nil)
  end

  @doc """
  Returns a map of all gauges and their extracted values from the metrics data.

  ## Examples

    ```
   Metrics.gauges(metrics)
    # => %{"memory.free.megs" => 2400, "memory.max.megs" => 8234 ...}
    ```

  """
  @spec gauges(data :: map()) :: map()
  def gauges(%{"gauges" => gauges} = data) do
    gauges
    |> Enum.map(
         fn {gauge_id, inner} ->
           {gauge_id, Map.get(inner, "value", nil)}
         end
       )
    |> Enum.into(%{})
  end

  @doc """
  Returns a map of containing the specified gauge data, with new keys

  Pass the metrics data followed by map of new_key => gauge_id

  ## Examples

   ```
   Metrics.map_gauges(metrics,  %{hn: "host.name", mm: "memory.max.megs"})
   # => %{hn: "production1", mm: 2048}
    ```

  """
  @spec map_gauges(data :: map(), keymap :: map()) :: map()
  def map_gauges(%{"gauges" => gauges} = data, keymap) do
    keymap
    |> Enum.map(
         fn {new_key, gauge_id} ->
           value = Map.get(gauges, gauge_id, %{})
                   |> Map.get("value", nil)
           {new_key, value}
         end
       )
    |> Enum.into(%{})
  end

  @doc """
  @doc """
  List the keys for all timers in the metrics.

  Requires a metrics map as the only parameter.

  ## Examples

    ```
    Shin.Metrics.timer_ids(metrics)
    # => ["org.opensaml.saml.metadata.resolver.impl.LocalDynamicMetadataResolver.exOverride.timer.resolve" ...]
    ```

  """
  @spec timer_ids(data :: map()) :: list()
  def timer_ids(%{"timers" => timers} = data) do
    Map.keys(timers)
  end

  @doc """
  Return the value for a timer.

  Specify the metrics map and key for the timer map to be extracted.

  ## Examples

    ```
    Shin.Metrics.timer(metrics, "org.opensaml.saml.metadata.resolver.impl.LocalDynamicMetadataResolver.exOverride.timer.resolve")
    # => %{"count" => 1, "duration_units" => "seconds" ...}
    ```

  """
  @spec timer(data :: map(), timer :: binary()) :: map()
  def timer(%{"timers" => timers} = data, timer) do
    Map.get(timers, timer, %{})
  end

  @doc """
  Returns a map of all timers and their details from the metrics data.

  ## Examples

    ```
   Metrics.timers(metrics)
    # => %{"org.opensaml.saml.metadata.resolver.impl.LocalDynamicMetadataResolver.exOverride.timer.resolve" => %{} ...}
    ```

  """
  @spec timers(data :: map()) :: map()
  def timers(%{"timers" => timers} = data) do
    timers
    |> Enum.map(
         fn {timer_id, inner} ->
           {timer_id, inner}
         end
       )
    |> Enum.into(%{})
  end

  @doc """
  Returns a map of containing the specified timer data, with new keys

  Pass the metrics data followed by map of new_key => timer_id

  ## Examples

   ```
   Metrics.map_timers(metrics,  %{timer1: "org.opensaml.saml.metadata.resolver.impl.LocalDynamicMetadataResolver.exOverride.timer.resolve"})
   # => %{timer1: %{"count" => 1, "duration_units" => "seconds" ...}}
    ```

  """
  @spec map_timers(data :: map(), keymap :: map()) :: map()
  def map_timers(%{"timers" => timers} = data, keymap) do
    keymap
    |> Enum.map(
         fn {new_key, timer_id} ->
           value = Map.get(timers, timer_id, %{})
           {new_key, value}
         end
       )
    |> Enum.into(%{})
  end

  #########

  @doc """
  Returns default (all) raw metrics from the IdP as a map.

  Pass an IdP as the only parameter.

  ## Examples

    ```
    {:ok, metrics} = Shin.Metrics.query(idp)
    ```

  """
  @spec query(idp :: binary | IdP.t()) :: {:ok, map()} | {:error, binary}
  def query(idp) do
    HTTP.get_data(idp, IdP.metrics_path(idp))
  end

  @doc """
  Returns the specified raw metrics group from the IdP as a map.

  Pass an IdP struct or URL binary as the first parameter and the name of the group as the second (as atom or binary)

  ## Examples

    ```
    {:ok, metrics} = Shin.Metrics.query(idp, :core)
    ```

  """
  @spec query(idp :: binary | IdP.t(), group :: atom | binary) ::
          {:ok, map()} | {:error, binary}
  def query(idp, group) do
    with {:ok, group} <- IdP.validate_metric_group(idp, group),
         metrics_path <- IdP.metrics_path(idp, group) do
      HTTP.get_data(idp, metrics_path)
    else
      err -> err
    end
  end


end
