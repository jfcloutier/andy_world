defmodule AndyWorldWeb.PlaygroundMonitor do
  @moduledoc """
    The top LiveView component
  """

  use AndyWorldWeb, :live_view

  def mount(_param, _session, socket) do
    {:ok, socket}
  end
end
