defmodule AndyWorld.Tile do
  @moduledoc """
  A tile
  """
  alias __MODULE__
  require Logger

  defstruct row: nil,
            column: nil,
            obstacle_height: 0,
            beacon_orientation: nil,
            ground_color: nil,
            ambient_light: nil

  # "<obstacle height * 10><beacon orientation><color><ambient * 10>|...."
  # _ = default, otherwise: obstacle in 0..9,  color in 0..7, ambient in 0..9, beacon in [N, S, E, W]
  def from_data(
        row,
        column,
        [height_s, beacon_s, color_s, ambient_s],
        default_ambient: default_ambient,
        default_color: default_color
      ) do
    %Tile{
      row: row,
      column: column,
      obstacle_height: convert_height(height_s),
      beacon_orientation: convert_beacon(beacon_s),
      ground_color: convert_color(color_s, default_color),
      ambient_light: convert_ambient(ambient_s, default_ambient)
    }
  end

  def has_obstacle?(tile) do
    tile.obstacle_height > 0 or tile.beacon_orientation != nil
  end

  def ground_color(%Tile{ground_color: ground_color}), do: ground_color
  def ambient_light(%Tile{ground_color: ambient_light}), do: ambient_light

  def reflected_light(_tile) do
    Logger.warn("Tile reflected light not implemented yet")
    0
  end

  defp convert_height("_"), do: 0

  defp convert_height(height_s) do
    {height, ""} = Integer.parse(height_s)
    height * 10
  end

  defp convert_beacon("_"), do: nil

  defp convert_beacon(beacon_s) when beacon_s in ["N", "S", "E", "W"] do
    beacon_s
  end

  defp convert_color("_", default_color), do: default_color

  defp convert_color(color_s, _default_color) do
    {color, ""} = Integer.parse(color_s)
    color
  end

  defp convert_ambient("_", default_ambient), do: default_ambient

  defp convert_ambient(ambient_s, _default_ambient) do
    {ambient, ""} = Integer.parse(ambient_s)
    ambient * 10
  end
end
