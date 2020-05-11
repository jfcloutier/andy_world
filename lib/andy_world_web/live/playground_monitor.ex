defmodule AndyWorldWeb.PlaygroundMonitor do
  @moduledoc """
    The top LiveView component
  """

  use AndyWorldWeb, :live_view

  alias Phoenix.PubSub
  require Logger

  def mount(_param, _session, socket) do
    if connected?(socket), do: subscribe()
    {:ok, assign(socket, robot_names: [])}
  end

  def handle_info({:robot_placed, %{robot: robot}}, socket) do
    Logger.info("#{__MODULE__} robot placed #{inspect(robot.name)}")
    robot_names = [robot.name | socket.assigns.robot_names] |> Enum.uniq()
    {:noreply, assign(socket, robot_names: robot_names)}
  end

  defp subscribe() do
    ~w(robot_placed)
    |> Enum.each(&PubSub.subscribe(AndyWorld.PubSub, &1))
  end
end
