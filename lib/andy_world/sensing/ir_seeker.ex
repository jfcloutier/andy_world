defmodule AndyWorld.Sensing.IRSeeker do
  @moduledoc "Sensing ir_seeker"

  alias AndyWorld.{Sensing, Space}

  @behaviour Sensing

  # Direction is :unknown or -120, -90, -60, -30, 0, 30, 60, 90, 120 degrees
  # Caveat: if closest visible robot is at an abs angle > 120, then it will hide another
  def sense(robot, ir_seeker_sensor, sense, _robot_tile, tiles, robots)
      when sense in [:direction, :direction_mod] do
    case Space.closest_robot_visible_to(robot, tiles, robots) do
      {:error, :not_found} ->
        :unknown

      {:ok, closest_robot} ->
        direction = Space.direction_to_other_robot(ir_seeker_sensor, robot, closest_robot)
        if abs(direction) > 120, do: :unknown, else: direction
    end
  end

  # Proximity is :unknown or 0..9, with 9 being closest
  # Caveat: if closest visible robot is at an abs angle > 120, then it will hide another
  def sense(robot, ir_seeker_sensor, sense, _robot_tile, tiles, robots)
      when sense in [:proximity, :proximity_mod] do
    case Space.closest_robot_visible_to(robot, tiles, robots) do
      {:error, :not_found} ->
        :unknown

      {:ok, closest_robot} ->
        direction = Space.direction_to_other_robot(ir_seeker_sensor, robot, closest_robot)

        if abs(direction) > 120 do
          :unknown
        else
          distance_cm = Space.distance_to_other_robot(robot, closest_robot)
          # Convert to 0..9 where 0 is 200
          9 - floor(distance_cm * 9 / 200)
        end
    end
  end
end
