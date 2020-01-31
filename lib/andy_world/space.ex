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
    {:ok, initial_state()}
  end

  #
  def handle_call(
        {:add_robot, name, node, row, column, orientation, motors: motors},
        _from,
        %State{robots: robots} = state
      ) do
    case validate_and_register(state,
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
            orientation: orientation,
            motors: motors,
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
        {:read, robot_name, sensor, sense},
        _from,
        %State{robots: robots, tiles: tiles} = state
      ) do
    robot = Map.fetch!(robots, robot_name)
    value = Robot.sense(robot, sensor, sense, tiles)
    {:reply, {:ok, value}, state}
  end

  def handle_cast({:event, robot_name, event}, %State{robots: robots} = state) do
    robot = Map.fetch!(robots, robot_name)
    updated_robot = Robot.record_event(robot, event)
    {:noreply, %State{state | robots: Map.put(robots, robot_name, updated_robot)}}
  end

  def occupied?(row, column, tiles, robots) do
    tile = get_tile(tiles, row, column)
    Tile.occupied?(tile) or Enum.any?(robots, &Robot.occupies?(&1, row, column))
  end

  def get_tile(tiles, row, column) do
    tiles |> Enum.at(row) |> Enum.at(column)
  end

  # Private

  defp initial_state() do
    %State{tiles: init_tiles()}
  end

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
end
