defmodule AndyWorld.Sensing.Color.Test do
  use ExUnit.Case

  alias AndyWorld.Sensing.Color
  require Logger

  setup_all do
    tiles = AndyWorld.tiles()
    default_color = Application.get_env(:andy_world, :default_color)
    default_ambient = Application.get_env(:andy_world, :default_ambient)

    {:ok,
     %{
       tiles: tiles,
       tile_defaults: %{color: Color.translate_color(default_color), ambient: default_ambient}
     }}
  end

  setup do
    AndyWorld.clear_robots()
  end

  describe "Seeing color" do
    test "seeing floor", %{tile_defaults: %{color: default_color}} do
      AndyWorld.place_robot(
        name: :andy,
        node: node(),
        row: 10,
        column: 10,
        orientation: 0,
        sensor_data: [
          %{
            port: "in2",
            type: :color,
            position: :front,
            height_cm: 2,
            aim: 0
          }
        ],
        motor_data: %{}
      )

      assert {:ok, ^default_color} = AndyWorld.read(name: :andy, sensor_id: "in2", sense: :color)
    end

    test "seeing food" do
      AndyWorld.place_robot(
        name: :andy,
        node: node(),
        row: 15,
        column: 9,
        orientation: 0,
        sensor_data: [
          %{
            port: "in2",
            type: :color,
            position: :front,
            height_cm: 2,
            aim: 0
          }
        ],
        motor_data: %{}
      )

      assert {:ok, :white} = AndyWorld.read(name: :andy, sensor_id: "in2", sense: :color)
    end
  end

  describe "Seeing ambient light" do
    test "See default ambient light", %{tile_defaults: %{ambient: default_ambient}} do
      AndyWorld.place_robot(
        name: :andy,
        node: node(),
        row: 10,
        column: 10,
        orientation: 0,
        sensor_data: [
          %{
            port: "in2",
            type: :color,
            position: :front,
            height_cm: 2,
            aim: 0
          }
        ],
        motor_data: %{}
      )
      assert {:ok, ^default_ambient} = AndyWorld.read(name: :andy, sensor_id: "in2", sense: :ambient)
    end

    test "See the darknesst" do
      AndyWorld.place_robot(
        name: :andy,
        node: node(),
        row: 10,
        column: 18,
        orientation: 0,
        sensor_data: [
          %{
            port: "in2",
            type: :color,
            position: :front,
            height_cm: 2,
            aim: 0
          }
        ],
        motor_data: %{}
      )
      assert {:ok, 10} = AndyWorld.read(name: :andy, sensor_id: "in2", sense: :ambient)
    end

  end
end
