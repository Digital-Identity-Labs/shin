defmodule MetricsExamples do

  def complete do

    {:ok, file} = File.read("test/support/complete_1.json")
    Jason.decode!(file)
  end

end