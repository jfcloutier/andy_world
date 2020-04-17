defmodule AndyWorld.Space do
  @moduledoc """
    Space sense maker
  """

  alias AndyWorld.{Tile, Robot, Sensing.Sensor}
  require Logger

  @simulated_step 0.2

  def occupied?(%Tile{} = tile) do
    {:ok, robots} = AndyWorld.robots()
    occupied?(tile, robots)
  end

  def occupied?(%Tile{row: row, column: column} = tile, robots) do
    Tile.has_obstacle?(tile) or
      Enum.any?(Map.values(robots), &Robot.occupies?(&1, row: row, column: column))
  end

  def unavailable_to?(
        %Tile{row: row, column: column} = tile,
        %Robot{} = robot
      ) do
    not Robot.occupies?(robot, row: row, column: column) and occupied?(tile)
  end

  def get_tile(tiles, row: row, column: column) do
    if on_playground?(row, column, tiles) do
      tile =
        tiles
        |> Enum.at(row)
        |> Enum.at(column)

      {:ok, tile}
    else
      {:error, :invalid}
    end
  end

  def get_tile(tiles, %Robot{x: x, y: y}) do
    get_tile(tiles, {x, y})
  end

  def get_tile(tiles, {x, y}) do
    get_tile(tiles, row: floor(y), column: floor(x))
  end

  @spec robot_tile(any, AndyWorld.Robot.t()) :: {:error, :invalid} | {:ok, any}
  def robot_tile(tiles, %Robot{x: x, y: y}) do
    get_tile(tiles, row: floor(y), column: floor(x))
  end

  @doc "Converts an angle so that angle in -180..180"
  def normalize_orientation(angle) do
    orientation = rem(angle, 360)

    cond do
      orientation <= -180 ->
        normalize_orientation(orientation + 360)

      orientation > 180 ->
        normalize_orientation(orientation - 360)

      true ->
        orientation
    end
  end

  @spec tile_adjoining_at_angle(integer, {non_neg_integer, non_neg_integer}, [%Tile{}]) ::
          {:ok, %Tile{}, non_neg_integer, non_neg_integer} | {:error, atom}
  @doc "Only tiles sharing a border are adjoining"
  def tile_adjoining_at_angle(angle, {x, y}, tiles) do
    {:ok, %Tile{row: row, column: column}} = get_tile(tiles, {x, y})
    normalized_angle = normalize_orientation(angle)

    {new_row, new_column} =
      cond do
        normalized_angle in -45..45 -> {row + 1, column}
        normalized_angle in 45..135 -> {row, column + 1}
        normalized_angle in 135..180 or normalized_angle in -180..-135 -> {row - 1, column}
        normalized_angle in -135..-45 -> {row, column - 1}
      end

    get_tile(tiles, row: new_row, column: new_column)
  end

  def closest_obstructed(tiles, %Robot{x: x, y: y}, orientation) do
    closest_obstructed(tiles, {x, y}, orientation)
  end

  def closest_obstructed(tiles, %Tile{row: row, column: column}, orientation) do
    closest_obstructed(tiles, {column, row}, orientation)
  end

  @doc "Find the {x,y} of the closest point of obstruction"
  def closest_obstructed(tiles, {x, y}, orientation) when is_number(x) and is_number(y) do
    # look fifth of a tile further
    step = @simulated_step
    delta_y = :math.cos(d2r(orientation)) * step
    delta_x = :math.sin(d2r(orientation)) * step
    # Logger.warn("delta_x=#{delta_x} delta_y=#{delta_y}")
    new_x = x + delta_x
    new_y = y + delta_y
    # Logger.warn("new_x=#{new_x} new_y=#{new_y}")

    # points to a different tile yet?
    if floor(new_x) != floor(x) or floor(new_y) != floor(y) do
      case get_tile(tiles, {new_x, new_y}) do
        {:ok, tile} ->
          if occupied?(tile) do
            {floor(x), floor(y)}
          else
            closest_obstructed(tiles, {new_x, new_y}, orientation)
          end

        {:error, _reason} ->
          {floor(x), floor(y)}
      end
    else
      closest_obstructed(tiles, {new_x, new_y}, orientation)
    end
  end

  @doc "Is a tile visible from a given location?"
  def tile_visible_to?(
        %Tile{} = target_tile,
        %Robot{x: x, y: y} = robot,
        tiles
      ) do
    tile_visible_from?(target_tile, {x, y}, tiles, robot)
  end

  def closest_visible_robot(%Robot{x: x, y: y} = robot, tiles) do
    {:ok, other_robots} = AndyWorld.robots_other_than(robot.name)

    visible_other_robots =
      Enum.filter(
        other_robots,
        fn other_robot ->
          {:ok, tile} = get_tile(tiles, other_robot)

          tile_visible_from?(
            tile,
            {x, y},
            tiles,
            other_robot
          )
        end
      )

    case Enum.sort(
           visible_other_robots,
           &(distance_to_other_robot(robot, &1) <= distance_to_other_robot(robot, &2))
         ) do
      [] ->
        {:error, :not_found}

      [closest_robot | _] ->
        {:ok, closest_robot}
    end
  end

  @spec direction_to_other_robot(
          atom | %{aim: integer},
          atom | %{orientation: integer, x: number, y: number},
          atom | %{x: number, y: number}
        ) :: float
  def direction_to_other_robot(sensor, robot, other_robot) do
    sensor_angle = Sensor.absolute_orientation(sensor.aim, robot.orientation)

    angle_perceived(robot.x, robot.y, sensor_angle, other_robot.x, other_robot.y)
  end

  def distance_to_other_robot(robot, other_robot) do
    delta_y_squared =
      (other_robot.y - robot.y)
      |> :math.pow(2)

    delta_x_squared =
      (other_robot.x - robot.x)
      |> :math.pow(2)

    distance = :math.sqrt(delta_y_squared + delta_x_squared)
    distance_cm = distance * Application.get_env(:andy_world, :tile_side_cm)
    distance_cm
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

  def angle_perceived(from_x, from_y, sensor_angle, target_x, target_y) do
    angle =
      ((target_y - from_y) / (target_x - from_x))
      |> :math.atan()
      |> r2d()

    angle - sensor_angle
  end

  def d2r(d) do
    d * :math.pi() / 180
  end

  def r2d(r) do
    r * 180 / :math.pi()
  end

  ### PRIVATE

  defp tile_visible_from?(
         %Tile{row: target_row, column: target_column} = target_tile,
         {x, y},
         tiles,
         # this robot is not an obstacle
         %Robot{} = robot
       ) do
    step = @simulated_step
    distance_x = target_column + 0.5 - x
    Logger.info("distance_x=#{distance_x}")
    distance_y = max(target_row + 0.5 - y, 0.0000000000001)
    Logger.info("distance_y=#{distance_y}")
    angle_r = :math.atan(distance_x / distance_y)
    Logger.info("angle_r=#{angle_r} => #{r2d(angle_r)} degrees")
    delta_y = :math.cos(angle_r) * step
    Logger.info("delta_y=#{delta_y}")
    delta_x = :math.sin(angle_r) * step
    Logger.info("delta_x=#{delta_x}")
    new_x = x + delta_x
    new_y = y + delta_y
    Logger.info("location={#{new_x},#{new_y}}")

    if floor(new_y) == target_row and floor(new_x) == target_column do
      true
    else
      case get_tile(tiles, {new_x, new_y}) do
        {:ok, tile} ->
          if unavailable_to?(tile, robot) do
            false
          else
            tile_visible_from?(target_tile, {new_x, new_y}, tiles, robot)
          end

        {:error, _reason} ->
          # we somehow missed the target tile but there was no obstruction
          true
      end
    end
  end
end
