defmodule AndyWorld.Playground do
  @moduledoc "Where the robots play"

  use GenServer

  alias AndyWorld.{Space, Tile, Robot}
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

  def handle_call(:tiles, _from, %State{tiles: tiles} = state) do
    {:reply, {:ok, tiles}, state}
  end

  def handle_call(:robots, _from, %State{robots: robots} = state) do
    {:reply, {:ok, robots}, state}
  end

  #
  def handle_call(
        {:place_robot, name, robot_node, row, column, orientation, sensors_data, motors_data},
        _from,
        %State{robots: robots} = state
      ) do
    case validate_and_register(
           state,
           name: name,
           node: robot_node,
           row: row,
           column: column,
           orientation: orientation
         ) do
      :ok ->
        robot =
          Robot.new(
            name: name,
            node: robot_node,
            orientation: orientation,
            sensors: sensors_data,
            motors: motors_data,
            row: row,
            column: column
          )

        {
          :reply,
          :ok,
          %State{
            state
            | robots:
                Map.put(
                  robots,
                  name,
                  robot
                )
          }
        }

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

    {
      :reply,
      :ok,
      %State{state | tiles: tiles, robots: Map.put(robots, robot.name, updated_robot)}
    }
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
    value = Robot.sense(robot, sensor_type, sense, tiles, Space.other_robots(robot, robots))
    {:reply, {:ok, value}, state}
  end

  def handle_cast({:event, robot_name, event}, %State{robots: robots} = state) do
    robot = Map.fetch!(robots, robot_name)
    updated_robot = Robot.record_event(robot, event)
    {:noreply, %State{state | robots: Map.put(robots, robot_name, updated_robot)}}
  end

  # Index = tile's cartesian coordinate
  defp init_tiles() do
    tiles_data = Application.get_env(:andy_world, :playground_tiles)
    default_ambient = Application.get_env(:andy_world, :default_ambient)
    default_color = Application.get_env(:andy_world, :default_color)

    Enum.reduce(
      Enum.with_index(tiles_data),
      [],
      fn {row_data, row}, acc ->
        [
          Enum.map(
            Enum.with_index(String.split(row_data, "|")),
            &Tile.from_data(
              row,
              elem(&1, 1),
              String.graphemes(elem(&1, 0)),
              default_ambient: default_ambient,
              default_color: default_color
            )
          )
          | acc
        ]
      end
    )
    |> Enum.reverse()
  end

  defp validate_and_register(
         %State{robots: robots, tiles: tiles},
         name: name,
         node: node,
         row: row,
         column: column,
         orientation: orientation
       ) do
    cond do
      name in Map.keys(robots) ->
        {:error, :name_taken}

      row not in Space.row_range(tiles) ->
        {:error, :invalid_row}

      column not in Space.column_range(tiles) ->
        {:error, :invalid_column}

      Space.occupied?(row, column, tiles, robots) ->
        {:error, :occupied}

      orientation not in -180..180 ->
        {:error, :invalid_orientation}

      node != node() and Node.connect(node) != true ->
        {:error, :failed_to_connect}

      true ->
        :ok
    end
  end
end
