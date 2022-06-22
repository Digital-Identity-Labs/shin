defmodule Shin do


  alias Shin.IdP
  alias Shin.HTTP

  def idp(idp, opts) do
    IdP.configure(idp, opts)
  end

  def ping?(idp) do
    client = Shin.HTTP.client(idp)
  end

  def metrics(idp) do
#    idp
#    |> HTTP.client()
#    |> HTTP.metrics()

  end

end
