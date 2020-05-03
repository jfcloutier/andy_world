defmodule AndyWorld.Sensing.IRSeeker.Test do
  use ExUnit.Case

  require Logger

  setup_all do
    {:ok, %{}}
  end

  setup do
    AndyWorld.clear_robots()
  end

  describe "Sensing with IR seeker" do
    test "Direction to other robot" do
      AndyWorld.place_robot(
        name: :andy,
        node: node(),
        row: 0,
        column: 0,
        orientation: 0,
        sensor_data: [
          %{
            port: "in1",
            type: :ir_seeker,
            position: :front,
            height_cm: 10,
            aim: 0
          }
        ],
        motor_data: []
      )

      assert {:ok, :unknown} =
               AndyWorld.read(name: :andy, sensor_id: "in1", sense: :direction_mod)

      AndyWorld.place_robot(
        name: :karl,
        node: node(),
        row: 10,
        column: 10,
        orientation: 0,
        sensor_data: [
          %{
            port: "in1",
            type: :ir_seeker,
            position: :front,
            height_cm: 10,
            aim: 0
          }
        ],
        motor_data: []
      )

      assert {:ok, 45} = AndyWorld.read(name: :andy, sensor_id: "in1", sense: :direction_mod)
      # hidden
      AndyWorld.move_robot(name: :andy, row: 0, column: 19)

      assert {:ok, :unknown} =
               AndyWorld.read(name: :andy, sensor_id: "in1", sense: :direction_mod)

      AndyWorld.move_robot(name: :andy, row: 0, column: 13)
      assert {:ok, -17} = AndyWorld.read(name: :andy, sensor_id: "in1", sense: :direction_mod)
      # Out of 120 degree range
      AndyWorld.move_robot(name: :andy, row: 19, column: 19)

      assert {:ok, :unknown} =
               AndyWorld.read(name: :andy, sensor_id: "in1", sense: :direction_mod)

      AndyWorld.move_robot(name: :andy, row: 19, column: 13)
      assert {:ok, -108} = AndyWorld.read(name: :andy, sensor_id: "in1", sense: :direction_mod)
    end

    test "Proximity to other robot" do
      AndyWorld.place_robot(
        name: :andy,
        node: node(),
        row: 0,
        column: 0,
        orientation: 0,
        sensor_data: [
          %{
            port: "in1",
            type: :ir_seeker,
            position: :front,
            height_cm: 10,
            aim: 0
          }
        ],
        motor_data: []
      )

      assert {:ok, :unknown} =
               AndyWorld.read(name: :andy, sensor_id: "in1", sense: :proximity_mod)

      AndyWorld.place_robot(
        name: :karl,
        node: node(),
        row: 10,
        column: 10,
        orientation: 0,
        sensor_data: [
          %{
            port: "in1",
            type: :ir_seeker,
            position: :front,
            height_cm: 10,
            aim: 0
          }
        ],
        motor_data: []
      )

      assert {:ok, 3} = AndyWorld.read(name: :andy, sensor_id: "in1", sense: :proximity_mod)

      AndyWorld.move_robot(name: :andy, row: 9, column: 9)
      assert {:ok, 9} = AndyWorld.read(name: :andy, sensor_id: "in1", sense: :proximity_mod)
      AndyWorld.move_robot(name: :andy, row: 11, column: 11)

      assert {:ok, :unknown} =
               AndyWorld.read(name: :andy, sensor_id: "in1", sense: :proximity_mod)

      AndyWorld.orient_robot(name: :andy, orientation: 180)
      assert {:ok, 9} = AndyWorld.read(name: :andy, sensor_id: "in1", sense: :proximity_mod)
    end
  end
end
