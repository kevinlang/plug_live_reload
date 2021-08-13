defmodule PlugLiveReloadTest do
  use ExUnit.Case

  import Plug.Test
  import Plug.Conn

  setup do
    Logger.disable(self())
    :ok
  end

  defp conn(path) do
    conn(:get, path)
  end

  test "renders frame with plug_live_reload.js" do
    conn =
      conn("/plug_live_reload/frame")
      |> PlugLiveReload.call([])

    assert conn.status == 200

    assert to_string(conn.resp_body) =~
             ~s[var interval = 100;\n]

    assert to_string(conn.resp_body) =~
             ~s[var targetWindow = "top";\n]

    refute to_string(conn.resp_body) =~
             ~s[<iframe]
  end

  test "injects live_reload for html requests if configured and contains <body> tag" do
    opts = PlugLiveReload.init([])

    conn =
      conn("/")
      |> put_resp_content_type("text/html")
      |> PlugLiveReload.call(opts)
      |> send_resp(200, "<html><body><h1>Plug</h1></body></html>")

    assert to_string(conn.resp_body) ==
             "<html><body><h1>Plug</h1><iframe hidden height=\"0\" width=\"0\" src=\"/plug_live_reload/frame\"></iframe></body></html>"
  end

  test "skips live_reload injection if html response missing body tag" do
    opts = PlugLiveReload.init([])

    conn =
      conn("/")
      |> put_resp_content_type("text/html")
      |> PlugLiveReload.call(opts)
      |> send_resp(200, "<h1>Phoenix</h1>")

    assert to_string(conn.resp_body) == "<h1>Phoenix</h1>"
  end

  test "skips live_reload if not html request" do
    opts = PlugLiveReload.init([])

    conn =
      conn("/")
      |> put_resp_content_type("application/json")
      |> PlugLiveReload.call(opts)
      |> send_resp(200, "")

    refute to_string(conn.resp_body) =~
             ~s(<iframe src="/plug_live_reload/frame")
  end

  test "skips live_reload if body is nil" do
    opts = PlugLiveReload.init([])

    conn =
      conn("/")
      |> put_resp_content_type("text/html")
      |> PlugLiveReload.call(opts)
      |> send_file(200, Path.join(File.cwd!(), "README.md"))

    assert conn.status == 200

    refute to_string(conn.resp_body) =~
             ~s(<iframe src="/plug_live_reload/frame")
  end

  # test "injects scoped live_reload with iframe attrs if configured" do
  #   opts = Phoenix.LiveReloader.init([])

  #   conn =
  #     conn("/")
  #     |> put_private(:phoenix_endpoint, MyApp.EndpointConfig)
  #     |> put_resp_content_type("text/html")
  #     |> Phoenix.LiveReloader.call(opts)
  #     |> send_resp(200, "<html><body><h1>Phoenix</h1></body></html>")

  #   assert to_string(conn.resp_body) ==
  #            "<html><body><h1>Phoenix</h1><iframe hidden height=\"0\" width=\"0\" src=\"/phoenix/live_reload/frame/foo/bar\" class=\"foo\" data-attr=\"bar\"></iframe></body></html>"
  # end

  # test "works with iolists as input" do
  #   opts = Phoenix.LiveReloader.init([])

  #   conn =
  #     conn("/")
  #     |> put_private(:phoenix_endpoint, MyApp.Endpoint)
  #     |> put_resp_content_type("text/html")
  #     |> Phoenix.LiveReloader.call(opts)
  #     |> send_resp(200, [
  #       "<html>",
  #       '<bo',
  #       [?d, ?y | ">"],
  #       "<h1>Phoenix</h1>",
  #       "</b",
  #       ?o,
  #       'dy>',
  #       "</html>"
  #     ])

  #   assert to_string(conn.resp_body) ==
  #            "<html><body><h1>Phoenix</h1><iframe hidden height=\"0\" width=\"0\" src=\"/phoenix/live_reload/frame\"></iframe></body></html>"
  # end

  # test "window target can be set to parent" do
  #   conn =
  #     conn("/phoenix/live_reload/frame")
  #     |> put_private(:phoenix_endpoint, MyApp.EndpointParentWindow)
  #     |> Phoenix.LiveReloader.call([])

  #   assert to_string(conn.resp_body) =~
  #     ~s[var targetWindow = "parent";\n]
  # end

  # test "wrong window target defaults to top" do
  #   Application.ge

  #   conn =
  #     conn("/plug_live_reload/frame")
  #     |> put_private(:phoenix_endpoint, MyApp.EndpointWrongWindow)
  #     |> Phoenix.LiveReloader.call([])

  #   assert to_string(conn.resp_body) =~
  #     ~s[var targetWindow = "top";\n]
  # end
end
