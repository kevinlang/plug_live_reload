defmodule PlugLiveReload do
  @moduledoc """
  Plug for live-reload detection in development. Specifically, this plug
  injects some Javascript at the bottom of each HTML page that listens to
  websocket events from `PlugLiveReload.Socket`. That Javascript will
  update the page.

  ## Usage

  Add the `PlugLiveReload` plug to your router. E.g.,

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

  This plug will only inject the Javascript if the content type of the response is `text/html`.
  This can be done with `Plug.Conn.put_resp_content_type/3`, as shown above.

  Additionally, this plug will only inject Javascript if the HTML response
  has a `<body>` tag.

  ## Configuration

  This plug is configured via opts passed to the plug. E.g.,

      plug PlugLiveReload, target_window: :top

  The following options are supported:

    * `:iframe_attrs` - attrs to be given to the iframe injected by
      live reload. Expects a keyword list of atom keys and string values.

    * `:target_window` - the window that will be reloaded, as an atom.
      Valid values are `:top` and `:parent`. An invalid value will
      default to `:top`.

  Additionally, one can disable the plug via an application config. This is
  useful for disabling it dynamically when running a Mix task, for example.
  This is typically not needed, as it is preferred to disable it via a
  `Mix.env()` guard check in your router, instead.

      Application.put_env(:plug_live_reload, :disable_plug, true)

  """

  import Plug.Conn
  @behaviour Plug

  reload_path = Application.app_dir(:plug_live_reload, "priv/plug_live_reload.js")
  @external_resource reload_path

  @html_before """
  <html><body>
  <script>
  """

  @html_after """
  #{File.read!(reload_path)}
  </script>
  </body></html>
  """

  def init(opts) do
    opts
  end

  def call(%Plug.Conn{path_info: ["plug_live_reload", "frame" | _suffix]} = conn, opts) do
    interval = opts[:interval] || 100
    target_window = get_target_window(opts[:target_window])

    conn
    |> put_resp_content_type("text/html")
    |> send_resp(200, [
      @html_before,
      ~s[var interval = #{interval};\n],
      ~s[var targetWindow = "#{target_window}";\n],
      @html_after
    ])
    |> halt()
  end

  def call(conn, opts) do
    disable_plug = Application.get_env(:plug_live_reload, :disable_plug, false)

    if disable_plug do
      conn
    else
      before_send_inject_reloader(conn, opts)
    end
  end

  defp before_send_inject_reloader(conn, opts) do
    register_before_send(conn, fn conn ->
      if conn.resp_body != nil and html?(conn) do
        resp_body = IO.iodata_to_binary(conn.resp_body)

        if has_body?(resp_body) do
          [page | rest] = String.split(resp_body, "</body>")
          body = [page, reload_assets_tag(opts), "</body>" | rest]
          put_in(conn.resp_body, body)
        else
          conn
        end
      else
        conn
      end
    end)
  end

  defp html?(conn) do
    case get_resp_header(conn, "content-type") do
      [] -> false
      [type | _] -> String.starts_with?(type, "text/html")
    end
  end

  defp has_body?(resp_body), do: String.contains?(resp_body, "<body")

  defp reload_assets_tag(opts) do
    attrs =
      Keyword.merge(
        [src: "/plug_live_reload/frame", hidden: true, height: 0, width: 0],
        Keyword.get(opts, :iframe_attrs, [])
      )

    IO.iodata_to_binary(["<iframe", attrs(attrs), "></iframe>"])
  end

  defp attrs(attrs) do
    Enum.map(attrs, fn
      {_key, nil} -> []
      {_key, false} -> []
      {key, true} -> [?\s, key(key)]
      {key, value} -> [?\s, key(key), ?=, ?", value(value), ?"]
    end)
  end

  defp key(key) do
    key
    |> to_string()
    |> String.replace("_", "-")
    |> Plug.HTML.html_escape_to_iodata()
  end

  defp value(value) do
    value
    |> to_string()
    |> Plug.HTML.html_escape_to_iodata()
  end

  defp get_target_window(:parent), do: "parent"

  defp get_target_window(_), do: "top"
end
