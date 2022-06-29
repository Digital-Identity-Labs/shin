#!/usr/bin/env elixir

Mix.install(
  [
    {:shin, "~> 0.1"},
    {:table_rex, "~> 3.1.1"}
  ]
)

urls = [
  "https://idp1.example.com/idp",
  "https://idp2.example.com/idp",
]

urls
|> Enum.map(
     fn url -> Shin.report(url)
               |> case do
                    {:ok, report} -> [url, report.java_version, report.java_vendor]
                    {:error, _msg} -> [url, "error", "error"]
                  end
     end
   )
|> TableRex.quick_render!(["IdP", "Java Version", "Java Vendor"])
|> IO.puts
