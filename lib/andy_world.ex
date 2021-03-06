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

  def slow_down_robots(dilation) do
    {:ok, robots} = GenServer.call(playground(), :robots)
    Enum.each(robots, &GenServer.cast({:clock, &1.node}, {:dilate, dilation}))
  end

  def resume(robot_name) do
    {:ok, robot} = GenServer.call(playground(), {:robot, robot_name})
    GenServer.cast({:clock, robot.node}, :resume)
  end

  def gm_tree(robot_name) do
    {:ok, robot} = GenServer.call(playground(), {:robot, robot_name})
    {:ok, gm_tree} = GenServer.call({:andy_portal, robot.node}, :gm_tree)
    gm_tree
  end

  # Return current and past round indices
  def round_indices(robot_name, gm_name, max_rounds) do
    {:ok, robot} = GenServer.call(playground(), {:robot, robot_name})

    {:ok, indices} =
      GenServer.call({:andy_portal, robot.node}, {:round_indices, gm_name, max_rounds})

    indices
  end

  # Return round state as a map from which to extract:
  # [predictions_in: [], perceptions: [], beliefs: [], prediction_errors_out: [], actions: []]
  def round_state(robot_name, gm_name, round_index) do
    {:ok, robot} = GenServer.call(playground(), {:robot, robot_name})

    {:ok, round_state} =
      GenServer.call({:andy_portal, robot.node}, {:round_state, gm_name, round_index})

    round_state
  end

  def broadcast(topic, payload, delay \\ 0) do
    spawn(fn ->
      Process.sleep(delay)
      PubSub.broadcast(AndyWorld.PubSub, topic, {String.to_atom(topic), payload})
    end)
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
    GenServer.call(playground(), {:actuate, robot_name, actuator_type, command, %{}})
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

  def prettify(map) when is_map(map) do
    strings = for {key, value} <- map, do: "#{key}: #{prettify(value)}"
    Enum.join(strings, ", ")
  end

  def prettify(term) when is_binary(term), do: term

  def prettify(term), do: inspect(term)
end
