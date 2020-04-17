defmodule AndyWorld.Sensing.Color do
  @moduledoc "Sensing color"

  alias AndyWorld.{Sensing, Tile}

  @behaviour Sensing

  def sensed(_robot, _sensor, :color, tile, _tiles) do
    Tile.ground_color(tile)
  end

  def sensed(_robot, _sensor, :ambient, tile, _tiles) do
    Tile.ambient_light(tile)
  end

  def sensed(_robot, _sensor, :reflected, tile, _tiles) do
    Tile.reflected_light(tile)
  end
end
