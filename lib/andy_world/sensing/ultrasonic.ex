defmodule AndyWorld.Sensing.Ultrasonic do
  @moduledoc "Sensing ultrasonic"

  alias AndyWorld.{Sensing}

  @behaviour Sensing

  def sensed(_robot, _sensor, _sense, _tile, _tiles, _other_robots) do
    # TODO
    nil
  end
end