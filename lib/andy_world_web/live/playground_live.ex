defmodule AndyWorldWeb.PlaygroundLive do
  @moduledoc """
    The dynamic visualization of the space when come to play.
  """

  use AndyWorldWeb, :live_view

  alias Phoenix.PubSub
  alias AndyWorld.Robot
  require Logger

  def mount(_params, _session, socket) do
    if connected?(socket), do: subscribe()
    {:ok, assign(socket, tiles: tiles())}
  end

  def handle_info({topic, _payload}, socket) when topic in [:robot_place, :robot_actuated] do
    {:noreply, assign(socket, tiles: tiles())}
  end

  def handle_info({topic, payload}, socket) do
    Logger.info("#{__MODULE__} HANDLING #{inspect(topic)} about #{inspect(payload.robot.name)}")
    {:noreply, socket}
  end

  def tile_class(tile) do
    text = cond do
      tile.robot != nil -> "has-text-dark"
      tile.obstacle_height > 0 -> "has-text-danger"
      tile.ground_color == 6 -> "has-text-success"
      true -> "has-text-white"
    end
      bg = cond do
        tile.obstacle_height > 0 -> "has-background-danger"
        tile.ground_color == 6 -> "has-background-success"
        true -> "has-background-white"
      end
      text <> " " <> bg
  end

  def tile_content(tile) do
    case tile.robot do
      nil -> "Z"
      %{name: name} -> String.at(name, 0) |> String.upcase()
    end
  end

  ## Private
  defp subscribe() do
    ~w(robot_placed robot_actuated)
    |> Enum.each(&PubSub.subscribe(AndyWorld.PubSub, &1))
  end

  defp tiles() do
    robots = AndyWorld.robots()

    for row <- AndyWorld.tiles() do
      for tile <- row do
        tile_map = Map.from_struct(tile)

        case Enum.find(robots, &Robot.occupies?(&1, tile)) do
          nil ->
            Map.put(tile_map, :robot, nil)

          robot ->
            Map.put(tile_map, :robot, %{
              name: "#{robot.name}",
              x: robot.x,
              y: robot.y,
              orientation: robot.orientation
            })
        end
      end
    end
  end

end
