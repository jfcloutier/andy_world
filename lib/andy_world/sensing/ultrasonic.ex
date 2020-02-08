defmodule AndyWorld.Sensing.Ultrasonic do
  @moduledoc "Sensing ultrasonic"

  alias AndyWorld.{Sensing, Space, Robot}

  @behaviour Sensing

  @max_distance_cm 250

  def sensed(
        %Robot{orientation: orientation, x: x, y: y},
        :ultrasonic,
        :distance,
        _tile,
        tiles,
        other_robots
      ) do
    tile_side = Application.get_env(:andy_world, :tile_side_cm)
    {far_x, far_y} = Space.furthest_unobstructed(tiles, x, y, orientation, other_robots)
    delta_y_sq = :math.pow(far_y - y, 2)
    delta_x_sq = :math.pow(far_x - x, 2)
    distance = :math.sqrt(delta_y_sq + delta_x_sq) * tile_side
    round(distance) |> min(@max_distance_cm)
  end
end
