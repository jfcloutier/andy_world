defmodule AndyWorldWeb.PlaygroundMonitor do
  @moduledoc """
    The top LiveView component
  """

  use AndyWorldWeb, :live_view

  alias Phoenix.PubSub
  require Logger

  @slow_down_increment 2

  @impl true
  def mount(_param, _session, socket) do
    if connected?(socket), do: subscribe()
    {:ok, assign(socket, robot_names: [], robots_paused: false, time_dilatation: 0)}
  end

  @impl true
  def handle_info({:robot_placed, %{robot: robot}}, socket) do
    Logger.info("#{__MODULE__} robot placed #{inspect(robot.name)}")
    robot_names = [robot.name | socket.assigns.robot_names] |> Enum.uniq()
    {:noreply, assign(socket, robot_names: robot_names)}
  end

  @impl true
  def handle_event("pause_or_resume_robots", _params, socket) do
    robots_paused? = socket.assigns.robots_paused
    if robots_paused?, do: AndyWorld.resume_robots(), else: AndyWorld.pause_robots()
    {:noreply, assign(socket, robots_paused: not robots_paused?)}
  end

  def handle_event("slow_down", _params, socket) do
    new_dilatation = socket.assigns.time_dilatation + @slow_down_increment
    AndyWorld.slow_down_robots(new_dilatation)
    {:noreply, assign(socket, time_dilatation: new_dilatation)}
  end

  def handle_event("normal_speed", _params, socket) do
    AndyWorld.slow_down_robots(0)
    {:noreply, assign(socket, time_dilatation: 0)}
  end

  def pause_or_resume_label(true), do: "Resume"
  def pause_or_resume_label(false), do: "Pause"

  def slow_down_label(time_dilatation) do
    "Slow down #{time_dilatation + @slow_down_increment}X"
  end

  defp subscribe() do
    ~w(robot_placed)
    |> Enum.each(&PubSub.subscribe(AndyWorld.PubSub, &1))
  end
end
