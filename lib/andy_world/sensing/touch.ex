defmodule AndyWorld.Sensing.Touch do
  @moduledoc "Sensing touch"

  alias AndyWorld.{Space, Robot, Sensing, Sensing.Sensor}

  @behaviour Sensing

  def sense(robot, touch_sensor, :touch, _tile, tiles, robots) do
    angle = Sensor.absolute_orientation(aim(touch_sensor.position), robot.orientation)

    case Space.tile_adjoining_at_angle(angle, Robot.locate(robot), tiles) do
      {:ok, tile} ->
        if Space.occupied?(tile, robots), do: :pressed, else: :released

      # tile is off the playground
      {:error, _reason} ->
        :pressed
    end
  end

  defp aim(:front), do: 0
  defp aim(:left), do: -90
  defp aim(:right), do: 90
  defp aim(:back), do: 180
end
