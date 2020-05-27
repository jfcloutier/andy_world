defmodule AndyWorldWeb.GMGraphLive do
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
       # gm_id => gm_name
       selected_gm_names: %{}
     )}
  end

  @impl true
  def handle_info({:robot_selected, robot_name}, socket) do
    {:noreply, assign(socket, robot_name: robot_name)}
  end

  def handle_info({:gm_selected, %{id: id, gm_name: gm_name}}, socket) do
    selected_gm_names = socket.assigns.selected_gm_names
    {:noreply, assign(socket, selected_gm_names: Map.put(selected_gm_names, "#{id}", gm_name))}
  end

  def handle_info({:showing_gms, ids}, socket) do
    selected_gm_names = socket.assigns.selected_gm_names

    updated_selected_gm_names =
      Enum.reduce(
        ids,
        %{},
        fn id, acc ->
          Map.put(acc, "#{id}", Map.get(selected_gm_names, "#{id}"))
        end
      )

    {:noreply, assign(socket, selected_gm_names: updated_selected_gm_names)}
  end

  defp subscribe() do
    ~w(robot_selected gm_selected showing_gms)
    |> Enum.each(&PubSub.subscribe(AndyWorld.PubSub, &1))
  end
end
