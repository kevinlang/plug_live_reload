defmodule PlugLiveReload do
  @moduledoc """
  Router for live-reload detection in development.

  ## Usage

  Add the `Phoenix.LiveReloader` plug within a `code_reloading?` block
  in your Endpoint, ie:

      if code_reloading? do
        socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
        plug Phoenix.CodeReloader
        plug Phoenix.LiveReloader
      end

  ## Configuration

  All live-reloading configuration must be done inside the `:live_reload`
  key of your endpoint, such as this:

      config :my_app, MyApp.Endpoint,
        ...
        live_reload: [
          patterns: [
            ~r{priv/static/.*(js|css|png|jpeg|jpg|gif)$},
            ~r{lib/my_app_web/views/.*(ex)$},
            ~r{lib/my_app_web/templates/.*(eex)$}
          ]
        ]

  The following options are supported:

    * `:patterns` - a list of patterns to trigger the live reloading.
      This option is required to enable any live reloading.

    * `:iframe_attrs` - attrs to be given to the iframe injected by
      live reload. Expects a keyword list of atom keys and string values.

    * `:target_window` - the window that will be reloaded, as an atom.
      Valid values are `:top` and `:parent`. An invalid value will
      default to `:top`.

    * `:url` - the URL of the live reload socket connection. By default
      it will use the browser's host and port.

    * `:suffix` - if you are running live-reloading on an umbrella app,
      you may want to give a different suffix to each socket connection.
      You can do so with the `:suffix` option:

          live_reload: [
            suffix: "/proxied/app/path"
          ]

      And then configure the endpoint to use the same suffix:

          if code_reloading? do
            socket "/phoenix/live_reload/socket/proxied/app/path", Phoenix.LiveReloader.Socket
            ...
          end

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
    patterns = Application.get_env(:plug_live_reload, :patterns)

    if patterns && patterns != [] do
      before_send_inject_reloader(conn, opts)
    else
      conn
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
        [hidden: true, height: 0, width: 0, src: "/plug_live_reload/frame"],
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
