defmodule AttributesExamples do

  @moduledoc false

  def basic_raw do
    File.read!("test/support/attributes.json")
  end

  def json_raw do
    Jason.decode!(basic_raw())
  end

end
