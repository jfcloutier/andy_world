defmodule AndyWorld do
  @moduledoc """
  AndyWorld provides a virtual playground for simulated robots
  """

  alias Phoenix.PubSub

  def playground() do
    :playground
  end

  def tiles() do
    {:ok, tiles} = GenServer.call(playground(), :tiles)
    tiles
  end

  def robots() do
    {:ok, robots} = GenServer.call(playground(), :robots)
    robots
  end

  def robot(robot_name) do
    {:ok, robot} = GenServer.call(playground(), {:robot, robot_name})
    robot
  end

  def pause_robots() do
    {:ok, robots} = GenServer.call(playground(), :robots)
    Enum.each(robots, &GenServer.cast({:clock, &1.node}, :pause))
  end

  def resume_robots() do
    {:ok, robots} = GenServer.call(playground(), :robots)
    Enum.each(robots, &GenServer.cast({:clock, &1.node}, :resume))
  end

  def pause(robot_name) do
    {:ok, robot} = GenServer.call(playground(), {:robot, robot_name})
    GenServer.cast({:clock, robot.node}, :pause)
  end

  def resume(robot_name) do
    {:ok, robot} = GenServer.call(playground(), {:robot, robot_name})
    GenServer.cast({:clock, robot.node}, :resume)
  end

  def broadcast(topic, payload) do
    PubSub.broadcast(AndyWorld.PubSub, topic, {String.to_atom(topic), payload})
  end

  ### Test support

  def place_robot(
        name: robot_name,
        node: node,
        row: row,
        column: column,
        orientation: orientation,
        sensor_data: sensor_data,
        motor_data: motor_data
      ) do
    :ok =
      GenServer.call(
        playground(),
        {:place_robot,
         name: robot_name,
         node: node,
         row: row,
         column: column,
         orientation: orientation,
         sensor_data: sensor_data,
         motor_data: motor_data}
      )

    robot(robot_name)
  end

  def read(name: robot_name, sensor_id: sensor_id, sense: sense) do
    GenServer.call(playground(), {:read, robot_name, sensor_id, sense})
  end

  def actuate(name: robot_name, actuator_type: actuator_type, command: command) do
    GenServer.call(playground(), {:actuate, robot_name, actuator_type, command})
  end

  def set_motor_control(name: robot_name, port: port, control: control, value: value) do
    GenServer.call(playground(), {:set_motor_control, robot_name, port, control, value})
  end

  def move_robot(name: robot_name, row: row, column: column) do
    {:ok, robot} =
      GenServer.call(playground(), {:move_robot, name: robot_name, row: row, column: column})

    robot
  end

  def orient_robot(name: robot_name, orientation: orientation) do
    {:ok, robot} =
      GenServer.call(playground(), {:orient_robot, name: robot_name, orientation: orientation})

    robot
  end

  def clear_robots() do
    GenServer.call(playground(), :clear_robots)
  end
end
