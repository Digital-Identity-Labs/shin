defmodule MetadataExamples do

  @moduledoc false

  def basic_raw do
    File.read!("test/support/metadata.xml")
  end

end
