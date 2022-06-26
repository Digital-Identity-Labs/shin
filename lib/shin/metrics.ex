defmodule Shin.Metrics do

  def gauge_ids(%{"gauges" => gauges} = data) do
    Map.keys(gauges)
  end

  def gauge(%{"gauges" => gauges} = data, gauge) do
    Map.get(gauges, gauge, %{})
    |> Map.get("value", nil)
  end

  def gauges(%{"gauges" => gauges} = data) do
    gauges
    |> Enum.map(
         fn {gauge_id, inner} ->
           {gauge_id, Map.get(inner, "value", nil)}
         end
       )
    |> Enum.into(%{})
  end

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

  def timer_ids(%{"timers" => timers} = data) do
    Map.keys(timers)
  end

  def timer(%{"timers" => timers} = data, timer) do
    Map.get(timers, timer, %{})
  end

  def timers(%{"timers" => timers} = data) do
    timers
    |> Enum.map(
         fn {timer_id, inner} ->
           {timer_id,inner}
         end
       )
    |> Enum.into(%{})
  end

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
