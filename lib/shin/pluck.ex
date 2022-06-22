defmodule Shin.Pluck do

  def max_memory(%{"gauges" => %{ "memory.max.megs" => %{"value" => max_memory } } } = data) do
    max_memory
  end

end
