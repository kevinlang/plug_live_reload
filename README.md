# PlugLiveReload

Adds live-reload functionality to [Plug](https://github.com/elixir-plug/plug) for development.

## Installation

You can use `plug_live_reload` in your projects by adding it to your `mix.exs` dependencies:

```
defp deps do
 [
   {:plug_live_reload, "~> 0.1.0", only: :dev}
 ]
end
```

Once that is done, you will want to add the plug to your `Plug.Router`.

```
defmodule MyApp.Router do
  use Plug.Router

  if Mix.env() == :dev do
    plug PlugLiveReload
  end
  
  plug :match
  plug :dispatch

  get "/" do
    conn
    |> put_resp_content_type("text/html")
    |> send_resp(200, "<html><body><h1>Plug</h1></body></html>")
  end
end
```

You will additionally need to make sure the `PlugLiveReload.Socket` handler is added
to your `Plug.Cowboy` child spec in your application.

```
def start(_type, _args) do
  children = [
    {Plug.Cowboy, scheme: :http, plug: MyApp.Router, options: [
      port: 4000,
      dispatch: dispatch()
    ]}
  ]

  opts = [strategy: :one_for_one, name: MyApp.Supervisor]
  Supervisor.start_link(children, opts)
end

if Mix.env() == :dev do
  def dispatch(),
    do: [
      {:_,
       [
        {"/plug_live_reload/socket", PlugLiveReload.Socket, []},
        {:_, Plug.Cowboy.Handler, {MyApp.Router, []}}
       ]}
    ]
else
  def dispatch(), do: nil
end
```

Lastly, you will need to configure which file paths to watch.

```
# config/dev.exs

config :plug_live_reload,
  patterns: [
    ~r"priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$",
  ]
```

You can find additional documentation for configuring the `PlugLiveReload` plug and the `PlugLiveReload.Socket` 
in their respective documentation pages.

## Backends

This project uses [`FileSystem`](https://github.com/falood/file_system) as a dependency to watch your filesystem whenever there is a change and it supports the following operating systems:

* Linux via [inotify](https://github.com/rvoicilas/inotify-tools/wiki) (installation required)
* Windows via [inotify-win](https://github.com/thekid/inotify-win) (no installation required)
* Mac OS X via fsevents (no installation required)
* FreeBSD/OpenBSD/~BSD via [inotify](https://github.com/rvoicilas/inotify-tools/wiki) (installation required)

There is also a `:fs_poll` backend that polls the filesystem and is available on all Operating Systems in case you don't want to install any dependency. You can configure the `:backend` in your `config/config.exs`:

```elixir
config :plug_live_reload,
  backend: :fs_poll
```

By default the entire application directory is watched by the backend. However, with some environments and backends, this may be inefficient, resulting in slow response times to file modifications. To account for this, it's also possible to explicitly declare a list of directories for the backend to watch, and additional options for the backend:

```elixir
config :plug_live_reload,
  dirs: [
    "priv/static",
    "priv/gettext",
    "lib/example_web/live",
    "lib/example_web/views",
    "lib/example_web/templates",
  ],
  backend: :fs_poll,
  backend_opts: [
    interval: 500
  ]
```

## Skipping remote CSS reload

All stylesheets are reloaded without a page refresh anytime a style is detected as having changed. In certain cases such as serving stylesheets from a remote host, you may wish to prevent unnecessary reload of these stylesheets during development. For this, you can include a `data-no-reload` attribute on the link tag, ie:

    <link rel="stylesheet" href="http://example.com/style.css" data-no-reload>

## Credits

Most of this code was adapted from [`phoenix_live_reload`](https://github.com/phoenix/phoenix_live_reload). 
The main difference is that this package is plug-specific and takes no Phoenix dependencies.

