ExUnit.start()

Config.Reader.read!("test/config.ex")
|> Application.put_all_env()

