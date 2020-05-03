defmodule AndyWorld.Sensing.Infrared.Test do
  use ExUnit.Case

  require Logger

  setup_all do
    {:ok, %{}}
  end

  setup do
    AndyWorld.clear_robots()
  end

  describe "Sensing beacon" do
    test "Heading to beacon" do
      AndyWorld.place_robot(
        name: :andy,
        node: node(),
        row: 9,
        column: 9,
        orientation: 0,
        sensor_data: [
          %{
            port: "in3",
            type: :infrared,
            position: :front,
            height_cm: 10,
            aim: 0
          }
        ],
        motor_data: []
      )

      assert {:ok, 0} = AndyWorld.read(name: :andy, sensor_id: "in3", sense: {:beacon_heading, 1})
      AndyWorld.orient_robot(name: :andy, orientation: 90)

      assert {:ok, -25} =
               AndyWorld.read(name: :andy, sensor_id: "in3", sense: {:beacon_heading, 1})

      AndyWorld.orient_robot(name: :andy, orientation: -90)

      assert {:ok, 25} =
               AndyWorld.read(name: :andy, sensor_id: "in3", sense: {:beacon_heading, 1})

      AndyWorld.orient_robot(name: :andy, orientation: 0)
      AndyWorld.move_robot(name: :andy, row: 0, column: 0)
      assert {:ok, 8} = AndyWorld.read(name: :andy, sensor_id: "in3", sense: {:beacon_heading, 1})
      AndyWorld.move_robot(name: :andy, row: 0, column: 19)
      # hidden by obstacle
      assert {:ok, 0} = AndyWorld.read(name: :andy, sensor_id: "in3", sense: {:beacon_heading, 1})

      AndyWorld.move_robot(name: :andy, row: 9, column: 19)

      assert {:ok, -14} =
               AndyWorld.read(name: :andy, sensor_id: "in3", sense: {:beacon_heading, 1})
    end
  end

  test "Distance to beacon" do
    AndyWorld.place_robot(
      name: :andy,
      node: node(),
      row: 9,
      column: 9,
      orientation: 0,
      sensor_data: [
        %{
          port: "in3",
          type: :infrared,
          position: :front,
          height_cm: 10,
          aim: 0
        }
      ],
      motor_data: []
    )

    # 80 cms is 40% of 200cm
    assert {:ok, 40} = AndyWorld.read(name: :andy, sensor_id: "in3", sense: {:beacon_distance, 1})
    AndyWorld.move_robot(name: :andy, row: 4, column: 16)
    # hidden
    assert {:ok, -128} =
             AndyWorld.read(name: :andy, sensor_id: "in3", sense: {:beacon_distance, 1})

    AndyWorld.move_robot(name: :andy, row: 10, column: 16)
    AndyWorld.orient_robot(name: :andy, orientation: 45)
    assert {:ok, 49} = AndyWorld.read(name: :andy, sensor_id: "in3", sense: {:beacon_distance, 1})

    AndyWorld.orient_robot(name: :andy, orientation: 180)
    # looking away from the beacon
    assert {:ok, -128} =
             AndyWorld.read(name: :andy, sensor_id: "in3", sense: {:beacon_distance, 1})
  end
end
