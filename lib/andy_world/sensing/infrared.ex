defmodule AndyWorld.Sensing.Infrared do
  @moduledoc "Sensing infrared"

  alias AndyWorld.{Sensing}

  @behaviour Sensing

  def sensed(_robot, _sensor, _sense, _tile, _tiles, _other_robots) do
    # TODO
    nil
  end
end