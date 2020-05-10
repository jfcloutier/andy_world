defmodule AndyWorldWeb.RobotLive do
  @moduledoc """
    The dynamic visualization of the space when come to play.
  """

  use AndyWorldWeb, :live_view

  alias Phoenix.PubSub
  require Logger

  def mount(_params, _session, socket) do
    if connected?(socket), do: subscribe()
   {:ok, assign(socket, robot_name: String.to_atom(socket.id))}
  end

  def handle_info({topic, payload}, socket) do
    Logger.info("#{__MODULE__} HANDLING #{inspect topic} about #{inspect payload.robot.name}")
    {:noreply, socket}
  end

  defp subscribe() do
    ~w(robot_placed robot_sensed robot_controlled robot_event)
    |> Enum.each(&PubSub.subscribe(AndyWorld.PubSub, &1))
  end

end
