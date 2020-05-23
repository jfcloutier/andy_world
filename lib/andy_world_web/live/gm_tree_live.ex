defmodule AndyWorldWeb.GMTreeLive do
  @moduledoc """
    The dynamic visualization of GM tree.
  """

  use AndyWorldWeb, :live_view

  alias Phoenix.PubSub
  require Logger

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: subscribe()
    {:ok,
     assign(socket,
       robot_name: nil,
       selected_gm_name: nil
     )}
  end

  @impl true
  def handle_info({:robot_selected, robot_name}, socket) do
    {:noreply, assign(socket, robot_name: robot_name)}
  end

  def handle_info({:gm_selected, gm_name}, socket) do
    {:noreply, assign(socket, selected_gm_name: gm_name)}
  end

  defp subscribe() do
    ~w(robot_selected gm_selected)
    |> Enum.each(&PubSub.subscribe(AndyWorld.PubSub, &1))
  end
end
