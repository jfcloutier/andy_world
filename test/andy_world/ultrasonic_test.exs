defmodule AndyWorld.Sensing.Ultrasonic.Test do
  use ExUnit.Case

  require Logger

  setup_all do
    {:ok, %{}}
  end

  setup do
    AndyWorld.clear_robots()
  end

  describe "Sensing distance" do
    test "Distance to edge" do
      AndyWorld.place_robot(
        name: :andy,
        node: node(),
        row: 10,
        column: 10,
        orientation: 180,
        sensor_data: [
          %{
            port: "in4",
            type: :ultrasonic,
            position: :front,
            height_cm: 2,
            aim: 0
          }
        ],
        motor_data: %{}
      )

      assert {:ok, 100} = AndyWorld.read(name: :andy, sensor_id: "in4", sense: :distance)

      AndyWorld.move_robot(name: :andy, row: 0, column: 0)
      assert {:ok, 2} = AndyWorld.read(name: :andy, sensor_id: "in4", sense: :distance)

    end

    test "Distance to obstacle" do
      AndyWorld.place_robot(
        name: :andy,
        node: node(),
        row: 7,
        column: 10,
        orientation: 90,
        sensor_data: [
          %{
            port: "in4",
            type: :ultrasonic,
            position: :front,
            height_cm: 2,
            aim: 0
          }
        ],
        motor_data: %{}
      )

      assert {:ok, 30} = AndyWorld.read(name: :andy, sensor_id: "in4", sense: :distance)
    end

    test "Distance to other robot" do
      AndyWorld.place_robot(
        name: :andy,
        node: node(),
        row: 10,
        column: 10,
        orientation: -135,
        sensor_data: [
          %{
            port: "in4",
            type: :ultrasonic,
            position: :front,
            height_cm: 2,
            aim: 0
          }
        ],
        motor_data: %{}
      )

      AndyWorld.place_robot(
        name: :karl,
        node: node(),
        row: 2,
        column: 2,
        orientation: 90,
        sensor_data: [
          %{
            port: "in4",
            type: :ultrasonic,
            position: :front,
            height_cm: 2,
            aim: 0
          }
        ],
        motor_data: %{}
      )

      assert {:ok, 115} = AndyWorld.read(name: :andy, sensor_id: "in4", sense: :distance)

      AndyWorld.move_robot(name: :karl, row: 9, column: 9)
      assert {:ok, 16} = AndyWorld.read(name: :andy, sensor_id: "in4", sense: :distance)

    end
  end
end
