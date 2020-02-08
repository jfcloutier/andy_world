defmodule AndyWorld.Sensing.Color do
  @moduledoc "Sensing color"

  alias AndyWorld.{Sensing, Tile}

  @behaviour Sensing

  def sensed(_robot, _sensor, :color, tile, _tiles, _other_robots) do
    Tile.ground_color(tile)
  end

  def sensed(_robot, _sensor, :ambient, tile, _tiles, _other_robots) do
    Tile.ambient_light(tile)
  end

  def sensed(_robot, _sensor, :reflected, tile, _tiles, _other_robots) do
    Tile.reflected_light(tile)
  end
end
