Application.put_env(:plug_live_reload, :patterns, [
  ~r{priv/static/.*(js|css|png|jpeg|jpg|gif)$}
])

ExUnit.start()
