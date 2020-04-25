defmodule AndyWorld.Sensing.Touch.Test do
  use ExUnit.Case

  require Logger

  setup_all do
    tiles = AndyWorld.tiles()
    default_color = Application.get_env(:andy_world, :default_color)
    default_ambient = Application.get_env(:andy_world, :default_ambient)
    {:ok, %{tiles: tiles, tile_defaults: %{color: default_color, ambient: default_ambient}}}
  end

  setup do
    AndyWorld.clear_robots()
  end

  describe "Touching" do
    test "not touching front" do
      AndyWorld.place_robot(
        name: :andy,
        node: node(),
        row: 5,
        column: 2,
        orientation: 90,
        sensor_data: [
          %{
            port: "in1",
            type: :touch,
            position: :front,
            height_cm: 2,
            aim: 0
          }
        ],
        motor_data: %{}
      )

      assert {:ok, :released} = AndyWorld.read(name: :andy, sensor_id: "in1", sense: :touch)
    end

    test "not touching side" do
      AndyWorld.place_robot(
        name: :andy,
        node: node(),
        row: 5,
        column: 2,
        orientation: 90,
        sensor_data: [
          %{
            port: "in1",
            type: :touch,
            position: :right,
            height_cm: 2,
            aim: 0
          }
        ],
        motor_data: %{}
      )

      assert {:ok, :released} = AndyWorld.read(name: :andy, sensor_id: "in1", sense: :touch)
    end

    test "touching front" do
      AndyWorld.place_robot(
        name: :andy,
        node: node(),
        row: 5,
        column: 2,
        orientation: 0,
        sensor_data: [
          %{
            port: "in1",
            type: :touch,
            position: :front,
            height_cm: 2,
            aim: 0
          }
        ],
        motor_data: %{}
      )

      assert {:ok, :pressed} = AndyWorld.read(name: :andy, sensor_id: "in1", sense: :touch)
    end

    test "touching side" do
      AndyWorld.place_robot(
        name: :andy,
        node: node(),
        row: 5,
        column: 2,
        orientation: 90,
        sensor_data: [
          %{
            port: "in1",
            type: :touch,
            position: :left,
            height_cm: 2,
            aim: 0
          }
        ],
        motor_data: %{}
      )

      assert {:ok, :pressed} = AndyWorld.read(name: :andy, sensor_id: "in1", sense: :touch)
    end
  end
end
