defmodule MetricsExamples do

  @moduledoc false

  def generic_raw do
    File.read!("test/support/star_destroyer.json")
  end

  def generic_parsed do
    Jason.decode!(generic_raw())
  end

  def complete_raw do
    File.read!("test/support/metrics_complete_1.json")
  end

  def complete_parsed do
    Jason.decode!(complete_raw())
  end

  def core_raw do
    File.read!("test/support/metrics_core_1.json")
  end

  def core_parsed do
    Jason.decode!(core_raw())
  end

end
