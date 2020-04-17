defmodule AndyWorld do
  @moduledoc """
  AndyWorld provides a virtual playground for simulated robots
  """

  def playground() do
    :global.whereis_name(:andy_world)
  end

  def tiles() do
    GenServer.call(playground(), :tiles)
  end

  def robots() do
    GenServer.call(playground(), :robots)
  end

  def robot(robot_name) do
    GenServer.call(playground(), {:robot, robot_name})
  end

  def robots_other_than(robot_name) do
    GenServer.call(playground(), {:robots_other_than, robot_name})
  end

  def place_robot(
        name: robot_name,
        node: node,
        row: row,
        column: column,
        orientation: orientation,
        sensor_data: sensor_data,
        motor_data: motor_data
      ) do
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
  end

  def move_robot(name: robot_name, row: row, column: column) do
    GenServer.call(playground(), {:move_robot, name: robot_name, row: row, column: column})
  end

  def orient_robot(name: robot_name, orientation: orientation) do
    GenServer.call(playground(), {:orient_robot, name: robot_name, orientation: orientation})
  end

  def clear_robots() do
    GenServer.call(playground(), :clear_robots)
  end
end
