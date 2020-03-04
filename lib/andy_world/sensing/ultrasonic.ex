defmodule AndyWorld.Sensing.Ultrasonic do
  @moduledoc "Sensing ultrasonic"

  alias AndyWorld.{Sensing, Space, Robot, Sensing.Sensor}

  @behaviour Sensing

  @max_distance_cm 250

  def sensed(
        %Robot{x: x, y: y} = robot,
        ultrasonic_sensor,
        :distance,
        _tile,
        tiles,
        other_robots
      ) do
    tile_side_cm = Application.get_env(:andy_world, :tile_side_cm)
    sensor_orientation = Sensor.absolute_orientation(ultrasonic_sensor.aim, robot.orientation)
    {far_x, far_y} = Space.closest_obstructed(tiles, x, y, sensor_orientation, other_robots)
    delta_y_sq = :math.pow(far_y - y, 2)
    delta_x_sq = :math.pow(far_x - x, 2)
    distance = :math.sqrt(delta_y_sq + delta_x_sq) * tile_side_cm
    round(distance) |> min(@max_distance_cm)
  end
end
