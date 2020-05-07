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
            sensors: %{},
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
    sensors = Enum.map(sensors_data, &{&1.port, Sensor.from(&1)}) |> Enum.into(%{})
    motors = Enum.map(motors_data, &{&1.port, Motor.from(&1)}) |> Enum.into(%{})

    %Robot{
      name: name,
      node: node,
      orientation: orientation,
      sensors: sensors,
      motors: motors,
      y: row * 1.0 + 0.5,
      x: column * 1.0 + 0.5
    }
  end

  def move_to(robot, row: row, column: column) do
    %Robot{robot | y: row * 1.0 + 0.5, x: column * 1.0 + 0.5}
  end

  def occupies?(%Robot{x: x, y: y}, row: row, column: column) do
    floor(y) == row and floor(x) == column
  end

  def locate(%Robot{x: x, y: y}) do
    {x, y}
  end

  def set_motor_control(%Robot{motors: motors} = robot, motor_port, control, value) do
    motor = Map.fetch!(motors, motor_port)

    Logger.debug(
      "Setting control #{inspect(control)} of motor #{motor.port} to #{inspect(value)}"
    )

    updated_motor = Motor.update_control(motor, control, value)
    %Robot{robot | motors: Map.put(motors, motor_port, updated_motor)}
  end

  def actuate(
        %Robot{} = robot,
        :motor,
        tiles,
        robots
      ) do
    Logger.info("Actuating motors: #{inspect(robot.motors)}")

    run_motors(robot, tiles, robots -- [robot])
    |> reset_motors()
  end

  def actuate(robot, _actuator_type, _tiles, _robots) do
    # Do nothing for now if not locomotion
    robot
  end

  def sense(%Robot{sensors: sensors} = robot, sensor_port, raw_sense, tiles, robots) do
    case Map.get(sensors, sensor_port) do
      nil ->
        Logger.warn("Robot #{robot.name} has no sensor with id #{inspect(sensor_port)}")
        nil

      sensor ->
        {x, y} = locate(robot)
        {:ok, tile} = Space.get_tile(tiles, {x, y})
        sense = unpack_sense(raw_sense)

        apply(Sensor.module_for(sensor.type), :sense, [
          robot,
          sensor,
          sense,
          tile,
          tiles,
          robots
        ])
    end
  end

  def record_event(%Robot{events: events} = robot, event) do
    max_events_remembered = Application.get_env(:andy_world, :max_events_remembered, 100)
    updated_events = [event | events] |> Enum.take(max_events_remembered)
    %Robot{robot | events: updated_events}
  end

  # Private

  defp unpack_sense({sense, channel}) when is_atom(sense), do: {sense, channel}

  defp unpack_sense(raw_sense) do
    case String.split("#{raw_sense}", "/") do
      [sense, channel] -> {String.to_existing_atom(sense), channel}
      _ -> raw_sense
    end
  end

  defp run_motors(
         %Robot{} = robot,
         tiles,
         other_robots
       ) do
    motors = Map.values(robot.motors)
    durations = Enum.map(motors, &Motor.run_duration(&1)) |> Enum.filter(&(&1 != 0))

    tick_duration =
      case durations do
        [] -> 0
        _ -> Enum.min(durations) |> min(@largest_tick_duration)
      end

    if tick_duration == 0 do
      Logger.info("Duration of actuation is 0. Do nothing.")
      robot
    else
      duration = Enum.max(durations)
      Logger.info("Running motors of #{robot.name} for #{duration} secs")
      ticks = ceil(duration / tick_duration)
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
            right_motors = Enum.filter(running_motors, &(&1.side == :right))

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

      new_orientation = Space.normalize_orientation(floor(position.orientation))

      Logger.info(
        "#{robot.name} is now at {#{position.x}, #{position.y}} with orientation #{
          new_orientation
        }"
      )

      %Robot{robot | orientation: new_orientation, x: position.x, y: position.y}
    end
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

  defp reset_motors(%Robot{motors: motors} = robot) do
    updated_motors =
      Enum.map(motors, fn {port, motor} -> {port, Motor.reset_controls(motor)} end)
      |> Enum.into(%{})

    %Robot{robot | motors: updated_motors}
  end

  defp new_orientation(
         orientation,
         left_forward_rotations,
         right_forward_rotations,
         degrees_per_rotation
       ) do
    effective_rotations = left_forward_rotations - right_forward_rotations

    delta_orientation = effective_rotations * degrees_per_rotation
    orientation + delta_orientation
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
    rotations = (left_forward_rotations + right_forward_rotations) / 2
    distance = rotations * tiles_per_rotation
    delta_y = :math.cos(Space.d2r(angle)) * distance
    delta_x = :math.sin(Space.d2r(angle)) * distance
    new_x = x + delta_x
    new_y = y + delta_y
    {:ok, tile} = Space.get_tile(tiles, {new_x, new_y})

    if Space.occupied?(tile, other_robots) do
      Logger.info("Can't move to new position #{inspect({new_x, new_y})}. Tile is occupied")
      {x, y}
    else
      {new_x, new_y}
    end
  end

  defp max(list, default \\ 0)
  defp max([], default), do: default
  defp max(list, _default) when is_list(list), do: Enum.max_by(list, &abs/1)
end
