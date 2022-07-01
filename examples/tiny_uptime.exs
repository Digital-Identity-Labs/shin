#!/usr/bin/env elixir
Mix.install([{:shin, "~> 0.1"}])
{:ok, data} = Shin.report("https://example.com/idp", :idp_info)
IO.puts(data.uptime)
