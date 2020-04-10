defmodule AndyWorld.Sensing.Touch do
  @moduledoc "Sensing touch"

  alias AndyWorld.{Space, Robot, Sensing, Sensing.Sensor}

  @behaviour Sensing

  def sensed(robot, touch_sensor, :touch, _tile, tiles, other_robots) do
    angle = Sensor.absolute_orientation(touch_sensor.aim, robot.orientation)

    case Space.tile_adjoining_at_angle(angle, Robot.locate(robot), tiles) do
      {:ok, tile} ->
        if Space.occupied?(tile, other_robots), do: :pressed, else: :released

      # tile is off the playground
      {:error, _reason} ->
        :pressed
    end
  end
end