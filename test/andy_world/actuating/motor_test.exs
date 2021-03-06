defmodule AndyWorld.Actuating.Motor.Test do
  use ExUnit.Case
  alias AndyWorld.Robot
  require Logger

  setup_all do
    {:ok,
     %{
       motor_data: [
         %{
           port: "outA",
           direction: 1,
           side: :left,
           controls: %{speed_mode: :rps, speed: 0, time: 0}
         },
         %{
           port: "outB",
           direction: 1,
           side: :right,
           controls: %{speed_mode: :rps, speed: 0, time: 0}
         },
         %{
           port: "outC",
           direction: 1,
           side: :center,
           controls: %{speed_mode: :rps, speed: 10, time: 5}
         }
       ]
     }}
  end

  setup do
    AndyWorld.clear_robots()
  end

  describe "Moving" do
    test "No motion", %{motor_data: motor_data} do
      AndyWorld.place_robot(
        name: :andy,
        node: node(),
        row: 9,
        column: 9,
        orientation: 0,
        sensor_data: [],
        motor_data: motor_data
      )

      before_location = AndyWorld.robot(:andy) |> Robot.locate()
      AndyWorld.actuate(name: :andy, actuator_type: :motor, command: :run_for)
      after_location = AndyWorld.robot(:andy) |> Robot.locate()
      assert before_location == after_location
    end

    test "Move forward up", %{motor_data: motor_data} do
      AndyWorld.place_robot(
        name: :andy,
        node: node(),
        row: 10,
        column: 10,
        orientation: 0,
        sensor_data: [],
        motor_data: motor_data
      )

      AndyWorld.set_motor_control(name: :andy, port: "outA", control: :speed, value: 1)
      AndyWorld.set_motor_control(name: :andy, port: "outA", control: :time, value: 10)
      AndyWorld.set_motor_control(name: :andy, port: "outB", control: :speed, value: 1)
      AndyWorld.set_motor_control(name: :andy, port: "outB", control: :time, value: 10)
      {before_x, before_y} = AndyWorld.robot(:andy) |> Robot.locate()
      AndyWorld.actuate(name: :andy, actuator_type: :motor, command: :run_for)
      {after_x, after_y} = AndyWorld.robot(:andy) |> Robot.locate()
      assert before_x == after_x
      assert after_y > before_y
    end

    test "Move forward up with obstacle", %{motor_data: motor_data} do
      AndyWorld.place_robot(
        name: :andy,
        node: node(),
        row: 5,
        column: 14,
        orientation: 0,
        sensor_data: [],
        motor_data: motor_data
      )

      AndyWorld.set_motor_control(name: :andy, port: "outA", control: :speed, value: 1)
      AndyWorld.set_motor_control(name: :andy, port: "outA", control: :time, value: 10)
      AndyWorld.set_motor_control(name: :andy, port: "outB", control: :speed, value: 1)
      AndyWorld.set_motor_control(name: :andy, port: "outB", control: :time, value: 10)
      {before_x, before_y} = AndyWorld.robot(:andy) |> Robot.locate()
      AndyWorld.actuate(name: :andy, actuator_type: :motor, command: :run_for)
      {after_x, after_y} = AndyWorld.robot(:andy) |> Robot.locate()
      assert before_x == after_x
      assert floor(after_y) == floor(before_y)
    end

    test "Move forward down", %{motor_data: motor_data} do
      AndyWorld.place_robot(
        name: :andy,
        node: node(),
        row: 10,
        column: 10,
        orientation: 180,
        sensor_data: [],
        motor_data: motor_data
      )

      AndyWorld.set_motor_control(name: :andy, port: "outA", control: :speed, value: 1)
      AndyWorld.set_motor_control(name: :andy, port: "outA", control: :time, value: 10)
      AndyWorld.set_motor_control(name: :andy, port: "outB", control: :speed, value: 1)
      AndyWorld.set_motor_control(name: :andy, port: "outB", control: :time, value: 10)
      {before_x, before_y} = AndyWorld.robot(:andy) |> Robot.locate()
      AndyWorld.actuate(name: :andy, actuator_type: :motor, command: :run_for)
      {after_x, after_y} = AndyWorld.robot(:andy) |> Robot.locate()
      assert before_x == after_x
      assert after_y < before_y
    end

    test "Move forward to the right", %{motor_data: motor_data} do
      AndyWorld.place_robot(
        name: :andy,
        node: node(),
        row: 10,
        column: 10,
        orientation: 90,
        sensor_data: [],
        motor_data: motor_data
      )

      AndyWorld.set_motor_control(name: :andy, port: "outA", control: :speed, value: 1)
      AndyWorld.set_motor_control(name: :andy, port: "outA", control: :time, value: 10)
      AndyWorld.set_motor_control(name: :andy, port: "outB", control: :speed, value: 1)
      AndyWorld.set_motor_control(name: :andy, port: "outB", control: :time, value: 10)
      {before_x, before_y} = AndyWorld.robot(:andy) |> Robot.locate()
      AndyWorld.actuate(name: :andy, actuator_type: :motor, command: :run_for)
      {after_x, after_y} = AndyWorld.robot(:andy) |> Robot.locate()
      assert after_x > before_x
      assert after_y == before_y
    end

    test "Move forward to the left", %{motor_data: motor_data} do
      AndyWorld.place_robot(
        name: :andy,
        node: node(),
        row: 10,
        column: 10,
        orientation: -90,
        sensor_data: [],
        motor_data: motor_data
      )

      AndyWorld.set_motor_control(name: :andy, port: "outA", control: :speed, value: 1)
      AndyWorld.set_motor_control(name: :andy, port: "outA", control: :time, value: 10)
      AndyWorld.set_motor_control(name: :andy, port: "outB", control: :speed, value: 1)
      AndyWorld.set_motor_control(name: :andy, port: "outB", control: :time, value: 10)
      {before_x, before_y} = AndyWorld.robot(:andy) |> Robot.locate()
      AndyWorld.actuate(name: :andy, actuator_type: :motor, command: :run_for)
      {after_x, after_y} = AndyWorld.robot(:andy) |> Robot.locate()
      assert after_x < before_x
      assert after_y == before_y
    end

    test "Move forward up and to the right", %{motor_data: motor_data} do
      AndyWorld.place_robot(
        name: :andy,
        node: node(),
        row: 10,
        column: 10,
        orientation: 45,
        sensor_data: [],
        motor_data: motor_data
      )

      AndyWorld.set_motor_control(name: :andy, port: "outA", control: :speed, value: 1)
      AndyWorld.set_motor_control(name: :andy, port: "outA", control: :time, value: 10)
      AndyWorld.set_motor_control(name: :andy, port: "outB", control: :speed, value: 1)
      AndyWorld.set_motor_control(name: :andy, port: "outB", control: :time, value: 10)
      {before_x, before_y} = AndyWorld.robot(:andy) |> Robot.locate()
      AndyWorld.actuate(name: :andy, actuator_type: :motor, command: :run_for)
      {after_x, after_y} = AndyWorld.robot(:andy) |> Robot.locate()
      assert after_x > before_x
      assert after_y > before_y
    end

    test "Move forward down and to the left", %{motor_data: motor_data} do
      AndyWorld.place_robot(
        name: :andy,
        node: node(),
        row: 10,
        column: 10,
        orientation: -135,
        sensor_data: [],
        motor_data: motor_data
      )

      AndyWorld.set_motor_control(name: :andy, port: "outA", control: :speed, value: 1)
      AndyWorld.set_motor_control(name: :andy, port: "outA", control: :time, value: 10)
      AndyWorld.set_motor_control(name: :andy, port: "outB", control: :speed, value: 1)
      AndyWorld.set_motor_control(name: :andy, port: "outB", control: :time, value: 10)
      {before_x, before_y} = AndyWorld.robot(:andy) |> Robot.locate()
      AndyWorld.actuate(name: :andy, actuator_type: :motor, command: :run_for)
      {after_x, after_y} = AndyWorld.robot(:andy) |> Robot.locate()
      assert after_x < before_x
      assert after_y < before_y
    end

    test "Move backward down", %{motor_data: motor_data} do
      AndyWorld.place_robot(
        name: :andy,
        node: node(),
        row: 10,
        column: 10,
        orientation: 0,
        sensor_data: [],
        motor_data: motor_data
      )

      AndyWorld.set_motor_control(name: :andy, port: "outA", control: :speed, value: -1)
      AndyWorld.set_motor_control(name: :andy, port: "outA", control: :time, value: 10)
      AndyWorld.set_motor_control(name: :andy, port: "outB", control: :speed, value: -1)
      AndyWorld.set_motor_control(name: :andy, port: "outB", control: :time, value: 10)
      {before_x, before_y} = AndyWorld.robot(:andy) |> Robot.locate()
      AndyWorld.actuate(name: :andy, actuator_type: :motor, command: :run_for)
      {after_x, after_y} = AndyWorld.robot(:andy) |> Robot.locate()
      assert before_x == after_x
      assert after_y < before_y
    end

    test "Move backward up", %{motor_data: motor_data} do
      AndyWorld.place_robot(
        name: :andy,
        node: node(),
        row: 10,
        column: 10,
        orientation: 180,
        sensor_data: [],
        motor_data: motor_data
      )

      AndyWorld.set_motor_control(name: :andy, port: "outA", control: :speed, value: -1)
      AndyWorld.set_motor_control(name: :andy, port: "outA", control: :time, value: 10)
      AndyWorld.set_motor_control(name: :andy, port: "outB", control: :speed, value: -1)
      AndyWorld.set_motor_control(name: :andy, port: "outB", control: :time, value: 10)
      {before_x, before_y} = AndyWorld.robot(:andy) |> Robot.locate()
      AndyWorld.actuate(name: :andy, actuator_type: :motor, command: :run_for)
      {after_x, after_y} = AndyWorld.robot(:andy) |> Robot.locate()
      assert before_x == after_x
      assert after_y > before_y
    end

    test "Move backward right", %{motor_data: motor_data} do
      AndyWorld.place_robot(
        name: :andy,
        node: node(),
        row: 10,
        column: 10,
        orientation: -90,
        sensor_data: [],
        motor_data: motor_data
      )

      AndyWorld.set_motor_control(name: :andy, port: "outA", control: :speed, value: -1)
      AndyWorld.set_motor_control(name: :andy, port: "outA", control: :time, value: 10)
      AndyWorld.set_motor_control(name: :andy, port: "outB", control: :speed, value: -1)
      AndyWorld.set_motor_control(name: :andy, port: "outB", control: :time, value: 10)
      {before_x, before_y} = AndyWorld.robot(:andy) |> Robot.locate()
      AndyWorld.actuate(name: :andy, actuator_type: :motor, command: :run_for)
      {after_x, after_y} = AndyWorld.robot(:andy) |> Robot.locate()
      assert after_x > before_x
      assert after_y == before_y
    end

    test "Move backward down and to the left", %{motor_data: motor_data} do
      AndyWorld.place_robot(
        name: :andy,
        node: node(),
        row: 10,
        column: 10,
        orientation: 45,
        sensor_data: [],
        motor_data: motor_data
      )

      AndyWorld.set_motor_control(name: :andy, port: "outA", control: :speed, value: -1)
      AndyWorld.set_motor_control(name: :andy, port: "outA", control: :time, value: 10)
      AndyWorld.set_motor_control(name: :andy, port: "outB", control: :speed, value: -1)
      AndyWorld.set_motor_control(name: :andy, port: "outB", control: :time, value: 10)
      {before_x, before_y} = AndyWorld.robot(:andy) |> Robot.locate()
      AndyWorld.actuate(name: :andy, actuator_type: :motor, command: :run_for)
      {after_x, after_y} = AndyWorld.robot(:andy) |> Robot.locate()
      assert after_x < before_x
      assert after_y < before_y
    end
  end

  describe "Turning" do
    test "Pointing up, turning right", %{motor_data: motor_data} do
      AndyWorld.place_robot(
        name: :andy,
        node: node(),
        row: 10,
        column: 10,
        orientation: 0,
        sensor_data: [],
        motor_data: motor_data
      )

      AndyWorld.set_motor_control(name: :andy, port: "outA", control: :speed, value: 0.1)
      AndyWorld.set_motor_control(name: :andy, port: "outA", control: :time, value: 1)
      AndyWorld.set_motor_control(name: :andy, port: "outB", control: :speed, value: -0.1)
      AndyWorld.set_motor_control(name: :andy, port: "outB", control: :time, value: 1)
      {before_x, before_y} = AndyWorld.robot(:andy) |> Robot.locate()
      AndyWorld.actuate(name: :andy, actuator_type: :motor, command: :run_for)
      {after_x, after_y} = AndyWorld.robot(:andy) |> Robot.locate()
      assert after_x == before_x
      assert after_y == before_y
      after_orientation = AndyWorld.robot(:andy).orientation
      assert after_orientation > 0
    end

    test "Pointing up, turning left", %{motor_data: motor_data} do
      AndyWorld.place_robot(
        name: :andy,
        node: node(),
        row: 10,
        column: 10,
        orientation: 0,
        sensor_data: [],
        motor_data: motor_data
      )

      AndyWorld.set_motor_control(name: :andy, port: "outA", control: :speed, value: -0.1)
      AndyWorld.set_motor_control(name: :andy, port: "outA", control: :time, value: 1)
      AndyWorld.set_motor_control(name: :andy, port: "outB", control: :speed, value: 0.1)
      AndyWorld.set_motor_control(name: :andy, port: "outB", control: :time, value: 1)
      {before_x, before_y} = AndyWorld.robot(:andy) |> Robot.locate()
      AndyWorld.actuate(name: :andy, actuator_type: :motor, command: :run_for)
      {after_x, after_y} = AndyWorld.robot(:andy) |> Robot.locate()
      assert after_x == before_x
      assert after_y == before_y
      after_orientation = AndyWorld.robot(:andy).orientation
      assert after_orientation < 0
    end

    test "Pointing right, turning right", %{motor_data: motor_data} do
      AndyWorld.place_robot(
        name: :andy,
        node: node(),
        row: 10,
        column: 10,
        orientation: 90,
        sensor_data: [],
        motor_data: motor_data
      )

      AndyWorld.set_motor_control(name: :andy, port: "outA", control: :speed, value: 0.1)
      AndyWorld.set_motor_control(name: :andy, port: "outA", control: :time, value: 1)
      AndyWorld.set_motor_control(name: :andy, port: "outB", control: :speed, value: -0.1)
      AndyWorld.set_motor_control(name: :andy, port: "outB", control: :time, value: 1)
      {before_x, before_y} = AndyWorld.robot(:andy) |> Robot.locate()
      AndyWorld.actuate(name: :andy, actuator_type: :motor, command: :run_for)
      {after_x, after_y} = AndyWorld.robot(:andy) |> Robot.locate()
      assert after_x == before_x
      assert after_y == before_y
      after_orientation = AndyWorld.robot(:andy).orientation
      assert after_orientation > 0
    end

    test "Pointing down, turning left", %{motor_data: motor_data} do
      AndyWorld.place_robot(
        name: :andy,
        node: node(),
        row: 10,
        column: 10,
        orientation: 180,
        sensor_data: [],
        motor_data: motor_data
      )

      AndyWorld.set_motor_control(name: :andy, port: "outA", control: :speed, value: -0.1)
      AndyWorld.set_motor_control(name: :andy, port: "outA", control: :time, value: 1)
      AndyWorld.set_motor_control(name: :andy, port: "outB", control: :speed, value: 0.1)
      AndyWorld.set_motor_control(name: :andy, port: "outB", control: :time, value: 1)
      {before_x, before_y} = AndyWorld.robot(:andy) |> Robot.locate()
      AndyWorld.actuate(name: :andy, actuator_type: :motor, command: :run_for)
      {after_x, after_y} = AndyWorld.robot(:andy) |> Robot.locate()
      assert after_x == before_x
      assert after_y == before_y
      after_orientation = AndyWorld.robot(:andy).orientation
      assert after_orientation < 180
    end

    test "Pointing left, turning right", %{motor_data: motor_data} do
      AndyWorld.place_robot(
        name: :andy,
        node: node(),
        row: 10,
        column: 10,
        orientation: -90,
        sensor_data: [],
        motor_data: motor_data
      )

      AndyWorld.set_motor_control(name: :andy, port: "outA", control: :speed, value: 0.1)
      AndyWorld.set_motor_control(name: :andy, port: "outA", control: :time, value: 1)
      AndyWorld.set_motor_control(name: :andy, port: "outB", control: :speed, value: -0.1)
      AndyWorld.set_motor_control(name: :andy, port: "outB", control: :time, value: 1)
      {before_x, before_y} = AndyWorld.robot(:andy) |> Robot.locate()
      AndyWorld.actuate(name: :andy, actuator_type: :motor, command: :run_for)
      {after_x, after_y} = AndyWorld.robot(:andy) |> Robot.locate()
      assert after_x == before_x
      assert after_y == before_y
      after_orientation = AndyWorld.robot(:andy).orientation
      assert after_orientation > -90
    end
  end
end
