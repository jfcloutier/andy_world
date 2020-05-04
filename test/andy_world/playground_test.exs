defmodule AndyWorld.Playground.Test do
  use ExUnit.Case

  alias AndyWorld.{Space, Tile, Robot}
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

  describe "Tiles" do
    test "Tile ordering", %{tiles: tiles} do
      [[first_tile | _] | _] = tiles
      assert first_tile.row == 0
      assert first_tile.column == 0
    end

    test "Tile properties", %{tiles: tiles, tile_defaults: tile_defaults} do
      {:ok, tile} = Space.get_tile(tiles, row: 17, column: 9)
      assert tile.beacon_orientation == "S"
      assert tile.obstacle_height == 10
      assert tile.ground_color == tile_defaults.color
      assert tile.ambient_light == tile_defaults.ambient
    end

    test "Tile occupancy", %{tiles: tiles} do
      {:ok, tile} = Space.get_tile(tiles, row: 5, column: 6)
      robots = AndyWorld.robots()
      assert false == Tile.has_obstacle?(tile)
      assert false == Space.occupied?(tile, robots)
    end
  end

  describe "Placing and moving robots" do
    test "Placing a robot", %{tiles: tiles} do
      :ok =
        GenServer.call(
          AndyWorld.playground(),
          {:place_robot,
           name: :andy,
           node: node(),
           row: 5,
           column: 6,
           orientation: 90,
           sensor_data: [],
           motor_data: []}
        )

      robots = AndyWorld.robots()
      andy = AndyWorld.robot(:andy)
      assert andy.name == :andy
      assert andy.x == 6.5
      assert andy.y == 5.5
      {:ok, tile} = Space.get_tile(tiles, {andy.x, andy.y})
      assert true == Space.occupied?(tile, robots)
    end

    test "Moving a robot" do
      robot =
        AndyWorld.place_robot(
          name: :andy,
          node: node(),
          row: 5,
          column: 6,
          orientation: 90,
          sensor_data: [],
          motor_data: []
        )

      assert robot.name == :andy

      robot = AndyWorld.move_robot(name: :andy, row: 0, column: 9)

      andy_robot = AndyWorld.robot(:andy)
      assert andy_robot == robot
      assert {9.5, 0.5} == Robot.locate(robot)
    end
  end
end
