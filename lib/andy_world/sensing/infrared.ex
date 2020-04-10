defmodule AndyWorld.Sensing.Infrared do
  @moduledoc """
  Sensing infrared beacon.
  Assumes at most one beacon set to some channel
  """

  alias AndyWorld.{Sensing, Space, Tile, Sensing.Sensor}

  @behaviour Sensing

  # -25 to 25 (-90 degrees to 90 degrees, 0 if undetected)
  def sensed(robot, infrared_sensor, {:beacon_heading, channel}, _robot_tile, tiles, other_robots) do
    case Space.find_beacon_tile(tiles, channel) do
      nil ->
        0

      %Tile{row: beacon_row, column: beacon_column} = beacon_tile ->
        if beacon_in_front?(
             beacon_tile,
             robot
           ) and Space.tile_visible?(beacon_tile, {robot.x, robot.y}, tiles, other_robots) do
          sensor_angle = Sensor.absolute_orientation(infrared_sensor.aim, robot.orientation)

          angle_perceived =
            Space.angle_perceived(
              robot.x,
              robot.y,
              sensor_angle,
              beacon_row + 0.5,
              beacon_column + 0.5
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
        tiles,
        other_robots
      ) do
    case Space.find_beacon_tile(tiles, channel) do
      nil ->
        -128

      %Tile{row: beacon_row, column: beacon_column} = beacon_tile ->
        if beacon_in_front?(
             beacon_tile,
             robot
           ) and Space.tile_visible?(beacon_tile, {robot.x, robot.y}, tiles, other_robots) do
          sensor_angle = Sensor.absolute_orientation(infrared_sensor.aim, robot.orientation)

          angle_perceived =
            Space.angle_perceived(
              robot.x,
              robot.y,
              sensor_angle,
              beacon_row + 0.5,
              beacon_column + 0.5
            )

          if abs(angle_perceived) <= 90 do
            delta_y_squared =
              (beacon_row + 0.5 - robot.y)
              |> :math.pow(2)

            delta_x_squared =
              (beacon_column + 0.5 - robot.x)
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