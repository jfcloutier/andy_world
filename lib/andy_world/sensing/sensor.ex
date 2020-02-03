defmodule AndyWorld.Sensing.Sensor do
  @moduledoc "Data about a sensor"

  alias __MODULE__
  alias AndyWorld.Sensing.{Sensor, Color, Infrared, IRSeeker, Touch, Ultrasonic}
  alias AndyWorld.Space

  defstruct port: nil,
            type: nil,
            # where the sensor is positioned on the robot, one of :left, :right, :top, :front, :back
            position: nil,
            # how high is the sensor riding on the robot
            height_cm: nil,
            # which way is the sensor pointing, # one of :left, :right, :top, :front, :back
            aim: nil

  def module_for(sensor_type) do
    case sensor_type do
      :color -> Color
      :infrared -> Infrared
      :ir_seeker -> IRSeeker
      :touch -> Touch
      :ultrasonic -> Ultrasonic
    end
  end

  def from(%{
        port: port,
        type: type,
        position: position,
        height_cm: height_cm,
        aim: aim
      }) do
    %Sensor{
      port: port,
      type: type,
      position: position,
      height_cm: height_cm,
      aim: aim
    }
  end

  def has_type?(%Sensor{type: type}, sensor_type), do: type == sensor_type

  def absolute_orientation(:front, robot_orientation), do: robot_orientation
  def absolute_orientation(:back, robot_orientation), do: Space.normalize_orientation(robot_orientation + 180)
  def absolute_orientation(:left, robot_orientation), do: Space.normalize_orientation(robot_orientation - 90)
  def absolute_orientation(:right, robot_orientation), do: Space.normalize_orientation(robot_orientation + 90)
end
