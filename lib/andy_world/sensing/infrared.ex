defmodule AndyWorld.Sensing.Infrared do
  @moduledoc """
  Sensing infrared beacon.
  Assumes at most one beacon set to some channel
  """

  alias AndyWorld.{Sensing, Space, Tile, Sensing.Sensor, Robot}

  @behaviour Sensing

  # -25 to 25 (-90 degrees to 90 degrees, 0 if undetected)
  def sensed(robot, infrared_sensor, {:beacon_heading, channel}, _robot_tile, tiles) do
    case Space.find_beacon_tile(tiles, channel) do
      nil ->
        0

      %Tile{} = beacon_tile ->
        if beacon_in_front?(
             beacon_tile,
             robot
           ) and Space.tile_visible_to?(beacon_tile, robot, tiles) do
          sensor_angle = Sensor.absolute_orientation(infrared_sensor.aim, robot.orientation)

          angle_perceived =
            Space.angle_perceived(
              Robot.locate(robot),
              sensor_angle,
              Tile.location(beacon_tile)
            )

          if abs(angle_perceived) <= 90, do: round(25 * angle_perceived / 90), else: 0
        else
          0
        end
    end
  end

  # 0 to 100 (percent, where 100% = 200cm), or -128 if undetected
  def sensed(
        robot,
        infrared_sensor,
        {:beacon_distance, channel},
        _robot_tile,
        tiles
      ) do
    case Space.find_beacon_tile(tiles, channel) do
      nil ->
        -128

      %Tile{} = beacon_tile ->
        if beacon_in_front?(
             beacon_tile,
             robot
           ) and Space.tile_visible_to?(beacon_tile, robot, tiles) do
          sensor_angle = Sensor.absolute_orientation(infrared_sensor.aim, robot.orientation)
          {beacon_x, beacon_y} = beacon_location = Tile.location(beacon_tile)

          angle_perceived =
            Space.angle_perceived(
              Robot.locate(robot),
              sensor_angle,
              beacon_location
            )

          if abs(angle_perceived) <= 90 do
            delta_y_squared =
              (beacon_y - robot.y)
              |> :math.pow(2)

            delta_x_squared =
              (beacon_x - robot.x)
              |> :math.pow(2)

            distance = :math.sqrt(delta_y_squared + delta_x_squared)

            distance_cm =
              (distance * Application.get_env(:andy_world, :tile_side_cm))
              |> min(200)

            # Convert to percent of 200 cm
            (distance_cm * 0.5)
            |> round
          else
            -128
          end
        else
          -128
        end
    end
  end

  # Private

  defp beacon_in_front?(
         %Tile{beacon_orientation: beacon_orientation, row: beacon_row, column: beacon_column},
         %Tile{row: robot_row, column: robot_column}
       ) do
    case beacon_orientation do
      "S" ->
        robot_row < beacon_row

      "N" ->
        robot_row > beacon_row

      "E" ->
        robot_column > beacon_column

      "W" ->
        robot_column < beacon_column

      nil ->
        false
    end
  end
end
