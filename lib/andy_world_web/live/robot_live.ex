defmodule AndyWorldWeb.RobotLive do
  @moduledoc """
    The dynamic visualization of the space when come to play.
  """

  use AndyWorldWeb, :live_view

  alias Phoenix.PubSub
  require Logger

  def mount(_params, _session, socket) do
    if connected?(socket), do: subscribe()
    robot_name = String.to_atom(socket.id)

    {:ok,
     assign(socket,
       robot_name: robot_name,
       robot_location: robot_location(robot_name),
       robot_orientation: robot_orientation(robot_name),
       robot_words: "Ready!",
       robot_sensings: []
     )}
  end

  def handle_info({:robot_actuated, %{robot: robot, command: :run_for}}, socket) do
    if robot.name == String.to_atom(socket.id) do
      {:noreply,
       assign(socket,
         robot_location: robot_location(robot.name),
         robot_orientation: robot_orientation(robot.name)
       )}
    else
      {:noreply, socket}
    end
  end

  def handle_info({:robot_actuated, %{robot: robot, command: :speak, params: words}}, socket) do
    if robot.name == String.to_atom(socket.id) do
      {:noreply,
       assign(socket,
         robot_words: words
       )}
    else
      {:noreply, socket}
    end
  end

  def handle_info(
        {:robot_sensed,
         %{
           robot: robot,
           sensor_id: sensor_id,
           sense: sense,
           value: value
         }},
        socket
      ) do
    if robot.name == String.to_atom(socket.id) do
      sensings = socket.assigns.robot_sensings
      sensor_type = Map.fetch!(robot.sensors, sensor_id) |> Map.fetch!(:type)
      updated_sensings = Keyword.put(sensings, :"#{sensor_type}/#{sense}", "#{inspect value}") |> Enum.sort()
      {:noreply, assign(socket, robot_sensings: updated_sensings)}
    else
      {:noreply, socket}
    end
  end

  def handle_info({_topic, _payload}, socket) do
    # Logger.info("Not handling #{inspect topic} with #{inspect payload}")
    {:noreply, socket}
  end

  defp subscribe() do
    ~w(robot_placed robot_actuated robot_sensed robot_controlled robot_event)
    |> Enum.each(&PubSub.subscribe(AndyWorld.PubSub, &1))
  end

  defp robot_orientation(name) do
    robot = AndyWorld.robot(name)
    "#{robot.orientation}&deg;"
  end

  defp robot_location(name) do
    robot = AndyWorld.robot(name)
    "(#{Float.round(robot.x, 1)}, #{Float.round(robot.y, 1)})"
  end
end
