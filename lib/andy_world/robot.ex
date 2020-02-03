defmodule AndyWorld.Robot do
  @moduledoc "What is known about a robot"

  alias __MODULE__
  alias AndyWorld.Space
  alias AndyWorld.Actuating.Motor
  alias AndyWorld.Sensing.Sensor

  require Logger

  # simulate motion at at most 0.1 sec deltas
  @largest_tick_duration 0.1

  defstruct name: nil,
            node: nil,
            # 0 is N, 90 is E, 180 is S, -90 is W
            orientation: 0,
            x: 0.0,
            y: 0.0,
            sensors: [],
            motors: %{},
            events: []

  def new(
        name: name,
        node: node,
        orientation: orientation,
        sensors: sensors_data,
        motors: motors_data,
        row: row,
        column: column
      ) do
    sensors = Enum.map(sensors_data, &Sensor.from(&1))
    motors = Enum.map(motors_data, &{&1.port, Motor.from(&1)}) |> Enum.into(%{})

    %Robot{
      name: name,
      node: node,
      orientation: orientation,
      sensors: sensors,
      motors: motors,
      x: row * 1.0,
      y: column * 1.0
    }
  end

  def occupies?(%Robot{x: x, y: y}, row, column) do
    floor(x) == row and floor(y) == column
  end

  def locate(%Robot{x: x, y: y}) do
    {floor(x), floor(y)}
  end

  def set_motor_control(%Robot{motors: motors} = robot, motor_port, control, value) do
    motor = Map.fetch!(motors, motor_port)
    updated_motor = Motor.update_control(motor, control, value)
    %Robot{robot | motors: Map.put(motors, motor_port, updated_motor)}
  end

  def actuate(
        %Robot{motors: motors} = robot,
        %{kind: :locomotion} = _intent,
        tiles,
        robots
      ) do
    updated_robot = run_motors(robot, tiles, Space.other_robots(robot, robots))
    reset_motors = Enum.map(motors, &Motor.reset_controls(&1))
    %Robot{updated_robot | motors: reset_motors}
  end

  def actuate(robot, _intent, _tiles, _robots) do
    # Do nothing for now
    robot
  end

  def find_sensor(%Robot{sensors: sensors}, type) do
    Enum.find(sensors, &(Sensor.has_type?(&1, type)))
  end

  def sense(robot, sensor_type, sense, tiles, other_robots) do
    case find_sensor(robot, sensor_type) do
      nil ->
        Logger.warn("Robot #{robot.name} has no sensor of type #{inspect(sensor_type)}")
        nil

      sensor ->
        {:ok, tile} = Space.get_tile(tiles, locate(robot))

        apply(Sensor.module_for(sensor_type), :sense, [
          robot,
          sensor,
          sense,
          tile,
          tiles,
          other_robots
        ])
    end
  end

  def record_event(%Robot{events: events} = robot, event) do
    %Robot{robot | events: [event | events]}
  end

  # Private

  defp run_motors(
         %Robot{motors: motors} = robot,
         tiles,
         other_robots
       ) do
    durations = Enum.map(motors, &Motor.run_duration(&1))
    tick_duration = durations |> Enum.min() |> min(@largest_tick_duration)
    ticks = ceil(Enum.max(durations) / tick_duration)
    degrees_per_rotation = Application.get_env(:andy_world, :degrees_per_motor_rotation)
    tiles_per_rotation = Application.get_env(:andy_world, :tiles_per_motor_rotation)

    position =
      Enum.reduce(
        0..ticks,
        %{orientation: robot.orientation, x: robot.x, y: robot.y},
        fn tick, acc ->
          secs_elapsed = tick * tick_duration
          running_motors = Enum.reject(motors, &(Motor.run_duration(&1) < secs_elapsed))
          left_motors = Enum.filter(running_motors, &(&1.side == :left))
          right_motors = Enum.filter(running_motors, &(&1.position == :right))

          activate_motors(
            left_motors,
            right_motors,
            tick_duration,
            acc,
            degrees_per_rotation,
            tiles_per_rotation,
            tiles,
            other_robots
          )
        end
      )

    %Robot{robot | orientation: position.orientation, x: position.x, y: position.y}
  end

  defp activate_motors(
         left_motors,
         right_motors,
         tick_duration,
         %{orientation: orientation, x: x, y: y},
         degrees_per_rotation,
         tiles_per_rotation,
         tiles,
         other_robots
       ) do
    # negative if backward-moving rotations
    left_forward_rotations =
      Enum.map(left_motors, &(Motor.rotations_per_sec(&1) * tick_duration)) |> max()

    right_forward_rotations =
      Enum.map(right_motors, &(Motor.rotations_per_sec(&1) * tick_duration)) |> max()

    angle =
      new_orientation(
        orientation,
        left_forward_rotations,
        right_forward_rotations,
        degrees_per_rotation
      )

    {new_x, new_y} =
      new_position(
        x,
        y,
        angle,
        left_forward_rotations,
        right_forward_rotations,
        tiles_per_rotation,
        tiles,
        other_robots
      )

    %{orientation: angle, x: new_x, y: new_y}
  end

  defp new_orientation(
         orientation,
         left_forward_rotations,
         right_forward_rotations,
         degrees_per_rotation
       ) do
    effective_rotations = left_forward_rotations - right_forward_rotations
    delta_orientation = (effective_rotations * degrees_per_rotation) |> floor()
    Space.normalize_orientation(orientation + delta_orientation)
  end

  defp new_position(
         x,
         y,
         angle,
         left_forward_rotations,
         right_forward_rotations,
         tiles_per_rotation,
         tiles,
         other_robots
       ) do
    rotations = (left_forward_rotations + right_forward_rotations) |> div(2)
    distance = rotations * tiles_per_rotation
    delta_x = :math.cos(angle) * distance
    delta_y = :math.sin(angle) * distance
    new_x = x + delta_x
    new_y = y + delta_y

    if Space.occupied?(floor(new_x), floor(new_y), tiles, other_robots) do
      {x, y}
    else
      {new_x, new_y}
    end
  end

  defp max(list, default \\ 0)
  defp max([], default), do: default
  defp max(list, _default) when is_list(list), do: Enum.max_by(list, &abs/1)
end
