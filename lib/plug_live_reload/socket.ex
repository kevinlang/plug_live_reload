defmodule PlugLiveReload.Socket do
  @moduledoc """
  Cowboy socket handler that sends websocket events. This websocket is what
  the `PlugLiveReload` plug's injected Javascript subscribes to in order
  to know when to reload.

  ## Usage

  Add the `PlugLiveReload.Socket` to your `Plug.Cowboy` child spec.

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

  This adds a new `:cowboy_websocket` handler for one route, `/plug_live_reload/socket`.
  All other routes will continue to be handled as usual by your plug router. This also makes it
  so that handler is not added at all in the `:dev` environment.

  ## Configuration

  This socket will only send events informing the page to reload if it the path of the changed
  resource matches any of the configured `:patterns`.

        config :plug_live_reload,
          patterns: [
            ~r"priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$",
          ]

  The configuration above will send an event if any of the JS/CSS/etc files in the `priv/static`
  change.
  """

  require Logger

  @behaviour :cowboy_websocket

  @impl :cowboy_websocket
  def init(request, state \\ %{}) do
    {:cowboy_websocket, request, state, %{idle_timeout: :infinity}}
  end

  @impl :cowboy_websocket
  def websocket_init(state) do
    {:ok, _} = Application.ensure_all_started(:plug_live_reload)

    if Process.whereis(:plug_live_reload_file_monitor) do
      FileSystem.subscribe(:plug_live_reload_file_monitor)
      {:ok, state}
    else
      Logger.warning("live reload backend not running")
      {:stop, state}
    end
  end

  @impl :cowboy_websocket
  def websocket_handle(_inframe, state) do
    {:ok, state}
  end

  @impl :cowboy_websocket
  def websocket_info({:file_event, _pid, {path, _event}}, state) do
    patterns = Application.get_env(:plug_live_reload, :patterns, [])

    if matches_any_pattern?(path, patterns) do
      asset_type = remove_leading_dot(Path.extname(path))
      Logger.debug("Live reload: #{Path.relative_to_cwd(path)}")
      {:reply, {:text, asset_type}, state}
    else
      {:ok, state}
    end
  end

  defp matches_any_pattern?(path, patterns) do
    path = to_string(path)

    Enum.any?(patterns, fn pattern ->
      String.match?(path, pattern) and !String.match?(path, ~r{(^|/)_build/})
    end)
  end

  defp remove_leading_dot("." <> rest), do: rest
  defp remove_leading_dot(rest), do: rest
end
