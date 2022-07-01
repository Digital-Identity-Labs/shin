defmodule MetricsExamples do

  @moduledoc false

  def generic do
    {:ok, file} = File.read("test/support/star_destroyer.json")
    Jason.decode!(file)
  end

  def complete do
    {:ok, file} = File.read("test/support/metrics_complete_1.json")
    Jason.decode!(file)
  end

  def core do
    {:ok, file} = File.read("test/support/metrics_core_1.json")
    Jason.decode!(file)
  end

end