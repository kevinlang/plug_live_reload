defmodule PlugLiveReload.Socket do
  require Logger

  @behaviour :cowboy_websocket

  @impl :cowboy_websocket
  def init(request, state) do
    {:cowboy_websocket, request, state}
  end

  @impl :cowboy_websocket
  def websocket_init(state) do
    {:ok, _} = Application.ensure_all_started(:plug_live_reload)
    patterns = Application.get_env(:plug_live_reload, :patterns)

    if Process.whereis(:phoenix_live_reload_file_monitor) do
      FileSystem.subscribe(:phoenix_live_reload_file_monitor)
      {:ok, Map.put(state, :patterns, patterns)}
    else
      Logger.warn("live reload backend not running")
      {:stop, state}
    end
  end

  @impl :cowboy_websocket
  def websocket_handle(_inframe, state) do
    {:ok, state}
  end

  @impl :cowboy_websocket
  def websocket_info({:file_event, _pid, {path, _event}}, %{patterns: patterns} = state) do
    if matches_any_pattern?(path, patterns) do
      asset_type = remove_leading_dot(Path.extname(path))
      Logger.debug("Live reload: #{Path.relative_to_cwd(path)}")
      {:reply, {:text, asset_type, state}}
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
