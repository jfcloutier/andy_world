defmodule AndyWorld.Space do
  @moduledoc """
    A simulated space-time for Andy robots
  """

  use GenServer

  alias AndyWorld.{Playground, Tile, Robot}
  require Logger

  defmodule State do
    defstruct tiles: [],
              robots: %{}
  end

  def child_spec(_) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, []},
      type: :worker,
      restart: :permanent,
      shutdown: 500
    }
  end

  def start_link() do
    Logger.info("Starting #{inspect(__MODULE__)}")
    GenServer.start_link(__MODULE__, :ok, name: {:global, :andy_world})
  end

  def init(_) do
    {:ok, %State{tiles: init_tiles()}}
  end

  #
  def handle_call(
        {:place_robot, name, node, row, column, orientation, sensors_data, motors_data},
        _from,
        %State{robots: robots} = state
      ) do
    case validate_and_register(
           state,
           name: name,
           node: node,
           row: row,
           column: column,
           orientation: orientation
         ) do
      :ok ->
        robot =
          Robot.new(
            name: name,
            node: node,
            orientation: orientation,
            sensors_data: sensors_data,
            motors: motors_data,
            row: row,
            column: column
          )

        {:reply, :ok,
         %State{
           state
           | robots:
               Map.put(
                 robots,
                 name,
                 robot
               )
         }}

      {:error, reason} ->
        {:reply, {:error, reason}}
    end
  end

  def handle_call(
        {:set_motor_control, robot_name, port, control, value},
        _from,
        %State{robots: robots, tiles: tiles} = state
      ) do
    robot = Map.fetch!(robots, robot_name)
    updated_robot = Robot.set_motor_control(robot, port, control, value)

    {:reply, :ok,
     %State{state | tiles: tiles, robots: Map.put(robots, robot.name, updated_robot)}}
  end

  def handle_call({:actuated, robot_name, intent}, _from, %{robots: robots, tiles: tiles} = state) do
    robot = Map.fetch!(robots, robot_name)
    updated_robot = Robot.actuate(robot, intent, tiles, robot)
    {:reply, :ok, %State{state | robots: Map.put(robots, robot.name, updated_robot)}}
  end

  def handle_call(
        {:read, robot_name, sensor_type, sense},
        _from,
        %State{robots: robots, tiles: tiles} = state
      ) do
    robot = Map.fetch!(robots, robot_name)
    value = Robot.sense(robot, sensor_type, sense, tiles, other_robots(robot, robots))
    {:reply, {:ok, value}, state}
  end

  def handle_cast({:event, robot_name, event}, %State{robots: robots} = state) do
    robot = Map.fetch!(robots, robot_name)
    updated_robot = Robot.record_event(robot, event)
    {:noreply, %State{state | robots: Map.put(robots, robot_name, updated_robot)}}
  end

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

  # Private

  # Index = tile's cartesian coordinate
  defp init_tiles() do
    default_ambient = Application.get_env(:andy_world, :default_ambient)
    default_color = Application.get_env(:andy_world, :default_color)

    Enum.reduce(
      Playground.data(),
      [],
      fn row_data, acc ->
        [
          Enum.map(
            String.split(row_data, "|"),
            &Tile.from_data(&1, default_ambient: default_ambient, default_color: default_color)
          )
          | acc
        ]
      end
    )
  end

  defp validate_and_register(%State{robots: robots, tiles: tiles},
         name: name,
         node: node,
         row: row,
         column: column,
         orientation: orientation
       ) do
    cond do
      name in Map.keys(robots) ->
        {:error, :name_taken}

      row not in row_range(tiles) ->
        {:error, :invalid_row}

      column not in column_range(tiles) ->
        {:error, :invalid_column}

      occupied?(row, column, tiles, robots) ->
        {:error, :occupied}

      orientation not in -180..180 ->
        {:error, :invalid_orientation}

      Node.connect(node) != true ->
        {:error, :failed_to_connect}

      true ->
        :ok
    end
  end

  defp row_range(tiles) do
    0..(Enum.count(tiles) - 1)
  end

  defp column_range([row | _] = _tiles) do
    0..(Enum.count(row) - 1)
  end

  defp on_playground?(row, column, tiles) do
    row in row_range(tiles) and column in column_range(tiles)
  end
end
