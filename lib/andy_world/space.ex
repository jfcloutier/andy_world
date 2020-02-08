defmodule AndyWorld.Space do
  @moduledoc """
    Space sense maker
  """

  alias AndyWorld.{Tile, Robot}
  require Logger

  def occupied?(%Tile{} = tile, row, column, robots) do
    Tile.has_obstacle?(tile) or Enum.any?(robots, &Robot.occupies?(&1, row, column))
  end

  def occupied?(row, column, tiles, robots) do
    case get_tile(tiles, row, column) do
      {:ok, tile} ->
        occupied?(tile, row, column, robots)

      # Any tile "off the playground" is implicitly occupied
      {:error, _reason} ->
        true
    end
  end

  def get_tile(tiles, {row, column}), do: get_tile(tiles, row, column)

  def get_tile(tiles, row, column) do
    if on_playground?(row, column, tiles) do
      tile = tiles |> Enum.at(row) |> Enum.at(column)
      {:ok, tile}
    else
      {:error, :invalid}
    end
  end

  def other_robots(robot, robots) do
    Enum.reject(robots, &(&1.name == robot.name))
  end

  def normalize_orientation(angle) do
    orientation = rem(angle, 360)

    cond do
      orientation <= -180 ->
        orientation + 360

      orientation > 180 ->
        orientation - 360

      true ->
        orientation
    end
  end

  @spec tile_adjoining_at_angle(integer, {non_neg_integer, non_neg_integer}, [%Tile{}]) ::
          {:ok, %Tile{}, non_neg_integer, non_neg_integer} | {:error, atom}
  def tile_adjoining_at_angle(angle, {row, column}, tiles) do
    {row, column} =
      cond do
        angle in -45..45 -> {row - 1, column}
        angle in 45..135 -> {row, column + 1}
        angle in 135..180 or angle in -180..-135 -> {row - 1, column}
        angle in -45..-135 -> {row, column - 1}
      end

    case get_tile(tiles, {row, column}) do
      {:ok, tile} -> {:ok, tile, row, column}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc "Find the {x,y} of the closest point of obstruction"
  def furthest_unobstructed(tiles, x, y, orientation, robots) do
    # look fifth of a tile further
    step = 0.2
    delta_x = :math.cos(orientation) * step
    delta_y = :math.sin(orientation) * step
    new_x = x + delta_x
    new_y = y + delta_y
    row = floor(new_x)
    column = floor(new_y)

    case get_tile(tiles, {row, column}) do
      {:ok, _tile} ->
        if occupied?(row, column, tiles, robots) do
          {x, y}
        else
          furthest_unobstructed(tiles, new_x, new_y, orientation, robots)
        end

      {:error, _reason} ->
        {x, y}
    end
  end

  def row_range(tiles) do
    0..(Enum.count(tiles) - 1)
  end

  def column_range([row | _] = _tiles) do
    0..(Enum.count(row) - 1)
  end

  def on_playground?(row, column, tiles) do
    row in row_range(tiles) and column in column_range(tiles)
  end

  # For now assume a single beacon channel
  def find_beacon_tile(tiles, _channel) do
    Enum.find(tiles, &(&1.beacon_orientation != nil))
  end

  def angle_perceived(robot, row, column) do
    # TODO
    0
  end
end
