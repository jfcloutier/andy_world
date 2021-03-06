defmodule AndyWorld.Playground do
  @moduledoc """
  Where the robots play.
  A square grid of equilateral tiles arranged in rows, with row 0 "down" and column 0 "left".any()
  North is up at 270 degrees. East is right at 0 degrees.
  """

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

  @spec start_link :: :ignore | {:error, any} | {:ok, pid}
  def start_link() do
    Logger.info("Starting #{inspect(__MODULE__)}")
    GenServer.start_link(__MODULE__, :ok, name: :playground)
  end

  @spec init(any) :: {:ok, AndyWorld.Playground.State.t()}
  def init(_) do
    {:ok, %State{tiles: init_tiles()}}
  end

  # An event was broadcasted by an Andy robot
  def handle_cast({:event, robot_name, event}, %State{robots: robots} = state) do
    robot = Map.fetch!(robots, robot_name)
    AndyWorld.broadcast("robot_event", %{robot: robot, event: event})
    {:noreply, %State{state | robots: Map.put(robots, robot_name, robot)}}
  end

  # A robot is placed on the playground
  def handle_call(
        {:place_robot,
         name: name,
         node: robot_node,
         row: row,
         column: column,
         orientation: orientation,
         sensor_data: sensors_data,
         motor_data: motors_data},
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

        Logger.info(
          "#{name} placed at #{inspect(Robot.locate(robot))} with orientation #{orientation}"
        )

        AndyWorld.broadcast("robot_placed", %{robot: robot, row: row, column: column})
        updated_robots = Map.put(robots, name, robot)
        {:reply, :ok, %State{state | robots: updated_robots}}

      {:error, reason} ->
        Logger.warn("Failed to place #{name}: #{reason}")
        {:reply, {:error, reason}, state}
    end
  end

  # A sensor is read for a sense. Allow concurrent reads.
  def handle_call(
        {:read, robot_name, sensor_id, sense},
        from,
        %State{robots: robots, tiles: tiles} = state
      ) do
    spawn_link(fn ->
      robot = Map.fetch!(robots, robot_name)
      value = Robot.sense(robot, sensor_id, sense, tiles, Map.values(robots))

      Logger.info(
        "Read #{robot_name}: #{inspect(sensor_id)} #{inspect(sense)} = #{inspect(value)}"
      )

      AndyWorld.broadcast("robot_sensed", %{
        robot: robot,
        sensor_id: sensor_id,
        sense: sense,
        value: value
      })

      GenServer.reply(from, {:ok, value})
    end)

    {:noreply, state}
  end

  # A motor control is set
  def handle_call(
        {:set_motor_control, robot_name, motor_id, control, value},
        _from,
        %State{robots: robots, tiles: tiles} = state
      ) do
    Logger.info("Set the #{control} of #{robot_name}'s motor #{motor_id} to #{inspect(value)}")
    robot = Map.fetch!(robots, robot_name)
    updated_robot = Robot.set_motor_control(robot, motor_id, control, value)

    AndyWorld.broadcast("robot_controlled", %{
      robot: updated_robot,
      motor_id: motor_id,
      control: control,
      value: value
    })

    {
      :reply,
      :ok,
      %State{state | tiles: tiles, robots: Map.put(robots, robot.name, updated_robot)}
    }
  end

  # Run a robot's motors
  def handle_call(
        {:actuate, robot_name, actuator_type, command, params},
        _from,
        %{robots: robots, tiles: tiles} = state
      ) do
    robot = Map.fetch!(robots, robot_name)

    updated_robot =
      if Robot.changed_by?(actuator_type, command) do
        Logger.info("Actuate #{robot.name}: #{inspect(command)} #{inspect(actuator_type)}")

        actuated_robot =
          Robot.actuate(robot, actuator_type, command, params, tiles, Map.values(robots))

        actuated_robot
      else
        robot
      end

    AndyWorld.broadcast("robot_actuated", %{
      robot: updated_robot,
      actuator_type: actuator_type,
      command: command,
      params: params
    })

    {:reply, :ok, %State{state | robots: Map.put(robots, robot.name, updated_robot)}}
  end

  ### TEST AND LIVE VIEW SUPPORT

  def handle_call(:tiles, _from, %State{tiles: tiles} = state) do
    {:reply, {:ok, tiles}, state}
  end

  def handle_call(:robots, _from, %State{robots: robots} = state) do
    {:reply, {:ok, Map.values(robots)}, state}
  end

  def handle_call({:robot, robot_name}, _from, %State{robots: robots} = state) do
    {:reply, Map.fetch(robots, robot_name), state}
  end

  def handle_call(:clear_robots, _from, state) do
    {:reply, :ok, %State{state | robots: %{}}}
  end

  def handle_call(
        {:move_robot, name: robot_name, row: row, column: column},
        _from,
        %State{robots: robots, tiles: tiles} = state
      ) do
    robot = Map.fetch!(robots, robot_name)
    {:ok, tile} = Space.get_tile(tiles, row: row, column: column)

    if Space.occupied?(tile, Map.values(robots) -- [robot]) do
      {:reply, {:error, :occupied}, state}
    else
      moved_robot = Robot.move_to(robot, row: row, column: column)
      updated_robots = Map.put(robots, robot_name, moved_robot)
      {:reply, {:ok, moved_robot}, %State{state | robots: updated_robots}}
    end
  end

  def handle_call(
        {:orient_robot, name: robot_name, orientation: orientation},
        _from,
        %State{robots: robots} = state
      ) do
    robot = Map.fetch!(robots, robot_name)
    oriented_robot = %Robot{robot | orientation: orientation}

    updated_robots = Map.put(robots, robot_name, oriented_robot)
    {:reply, {:ok, oriented_robot}, %State{state | robots: updated_robots}}
  end

  # Index = tile's cartesian coordinate
  # A list of rows
  defp init_tiles() do
    tiles_data = Application.get_env(:andy_world, :playground_tiles)
    default_ambient = Application.get_env(:andy_world, :default_ambient)
    default_color = Application.get_env(:andy_world, :default_color)
    row_count = Enum.count(tiles_data)

    Enum.reduce(
      Enum.with_index(tiles_data),
      [],
      fn {row_data, row}, acc ->
        [
          Enum.map(
            Enum.with_index(String.split(row_data, "|")),
            &Tile.from_data(
              row_count - row - 1,
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
  end

  defp validate_and_register(
         %State{robots: robots, tiles: tiles},
         name: name,
         node: node,
         row: row,
         column: column,
         orientation: orientation
       ) do
    {:ok, tile} = Space.get_tile(tiles, row: row, column: column)

    cond do
      name in Map.keys(robots) ->
        {:error, :name_taken}

      row not in Space.row_range(tiles) ->
        {:error, :invalid_row}

      column not in Space.column_range(tiles) ->
        {:error, :invalid_column}

      Space.occupied?(tile, Map.values(robots)) ->
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
