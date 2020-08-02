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
    Logger.info(
      "#{__MODULE__} NOT HANDLING #{inspect(topic)} about #{inspect(payload.robot.name)}"
    )

    {:noreply, socket}
  end

  ## Private

  defp tile_class(tile) do
    color = tile_color(tile)

    text_color =
      cond do
        tile.robot != nil or tile.beacon_orientation != nil ->
          if tile.ambient_light <= 60,
            do: "has-text-weight-bold has-text-white",
            else: "has-text-weight-bold has-text-dark"

        true ->
          "has-text-#{color}"
      end

    bg_color = "has-background-#{color}"
    text_color <> " " <> bg_color
  end

  defp tile_content(tile) do
    cond do
      tile.robot != nil ->
        String.at(tile.robot.name, 0) |> String.upcase()

      tile.beacon_orientation != nil ->
        case tile.beacon_orientation do
          "N" -> "&uarr;"
          "E" -> "&rarr;"
          "S" -> "&darr;"
          "W" -> "&larr;"
        end

      true ->
        # Will be white on white. Gives the tile width even if "empty".
        "Z"
    end
  end

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

  defp tile_color(tile) do
    cond do
      tile.obstacle_height > 0 -> "info"
      tile.ground_color == 6 -> "success"
      tile.ambient_light <= 10 -> "grey-darker"
      tile.ambient_light <= 20 -> "grey-dark"
      tile.ambient_light <= 40 -> "grey-dark"
      tile.ambient_light <= 60 -> "grey"
      tile.ambient_light < 80 -> "grey-lighter"
      tile.ambient_light < 90 -> "white-ter"
      tile.ambient_light < 100 -> "white-bis"
      true -> "white"
    end
  end
end
