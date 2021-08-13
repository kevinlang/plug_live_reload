defmodule PlugLiveReload.SocketTest do
  use ExUnit.Case
  alias PlugLiveReload.Socket

  setup do
    Logger.disable(self())
    :ok
  end

  defp file_event(path, event) do
    {:file_event, self(), {path, event}}
  end

  defp default_state() do
    %{
      patterns: [
        ~r{priv/static/.*(js|css|png|jpeg|jpg|gif)$}
      ]
    }
  end

  test "sends notification for js" do
    assert {:reply, {:text, "js"}, _state} =
             Socket.websocket_info(
               file_event("priv/static/plug_live_reload.js", :created),
               default_state()
             )
  end

  test "sends notification for css" do
    assert {:reply, {:text, "css"}, _state} =
             Socket.websocket_info(
               file_event("priv/static/plug_live_reload.css", :created),
               default_state()
             )
  end

  test "sends notification for png" do
    assert {:reply, {:text, "png"}, _state} =
             Socket.websocket_info(
               file_event("priv/static/plug_live_reload.png", :created),
               default_state()
             )
  end
end
