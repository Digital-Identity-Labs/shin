defmodule Shin.Metrics do

  @spec gauge_ids(data :: map()) :: list()
  def gauge_ids(%{"gauges" => gauges} = data) do
    Map.keys(gauges)
  end

  @spec gauge(data :: map(), gauge :: binary()) :: binary | integer
  def gauge(%{"gauges" => gauges} = data, gauge) do
    Map.get(gauges, gauge, %{})
    |> Map.get("value", nil)
  end

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

  @spec timer_ids(data :: map()) :: list()
  def timer_ids(%{"timers" => timers} = data) do
    Map.keys(timers)
  end

  @spec timer(data :: map(), timer :: binary()) :: map()
  def timer(%{"timers" => timers} = data, timer) do
    Map.get(timers, timer, %{})
  end

  @spec timers(data :: map()) :: map()
  def timers(%{"timers" => timers} = data) do
    timers
    |> Enum.map(
         fn {timer_id, inner} ->
           {timer_id,inner}
         end
       )
    |> Enum.into(%{})
  end

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

end
