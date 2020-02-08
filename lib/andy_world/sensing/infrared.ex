defmodule AndyWorld.Sensing.Infrared do
  @moduledoc "Sensing infrared"

  alias AndyWorld.{Sensing, Space, Tile}

  @behaviour Sensing

  # Assumes only one beacon for now
  # 0 to 100 (percent, where 100% = 200cm), or -128 if undetected
  def sensed(robot, :infrared, {:beacon_heading, channel}, robot_tile, tiles, other_robots) do
    case Space.find_beacon_tile(tiles, channel) do
      nil ->
        0

      %Tile{row: beacon_row, column: beacon_column} = beacon_tile ->
        if beacon_visible_to_robot?(beacon_tile, robot_tile, robot) do
          angle = Space.angle_perceived(robot, beacon_row, beacon_column)
          round(90 * angle / 25)
        else
          0
        end
    end
  end

  # Assumes only one beacon for now
  # -25 to 25 (-90 degrees to 90 degrees, 0 if undetected)
  def sensed(robot, :infrared, {:beacon_distance, _channel}, robot_tile, tiles, other_robots) do
    case Space.find_beacon_tile(tiles, _channel) do
      nil ->
        -128

      %Tile{row: beacon_row, column: beacon_column} = beacon_tile ->
        if beacon_visible_to_robot?(beacon_tile, robot_tile, robot) do
          angle = Space.angle_perceived(robot, beacon_row, beacon_column)
          # TODO - given angle and relative positions, find distance
          -128
        else
          -128
        end
    end
  end

  # Private

  defp beacon_visible_to_robot?(beacon_tile, robot_tile, robot) do
    # TODO
    false
  end
end
