defmodule AndyWorld.Test do
  use ExUnit.Case

  alias AndyWorld.{Space, Tile, Robot}
  require Logger

  setup_all do
    {:ok, tiles} = AndyWorld.tiles()
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
      {:ok, robots} = AndyWorld.robots()
      assert false == Tile.has_obstacle?(tile)
      assert false == Space.occupied?(tile, robots)
    end
  end

  describe "Robots" do
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
           sensor_data: %{},
           motor_data: %{}}
        )

      {:ok, %{andy: andy} = robots} = AndyWorld.robots()
      assert andy.name == :andy
      assert andy.x == 6.5
      assert andy.y == 5.5
      {:ok, tile} = Space.get_tile(tiles, {andy.x, andy.y})
      assert true == Space.occupied?(tile, robots)
    end

    test "Moving a robot" do
      :ok =
        GenServer.call(
          AndyWorld.playground(),
          {:place_robot,
           name: :andy,
           node: node(),
           row: 5,
           column: 6,
           orientation: 90,
           sensor_data: %{},
           motor_data: %{}}
        )

      :ok =
        GenServer.call(
          AndyWorld.playground(),
          {:move_robot, name: :andy, row: 0, column: 9}
        )

      {:ok, robots} = AndyWorld.robots()
      robot = Map.fetch!(robots, :andy)
      assert {9.5, 0.5} == Robot.locate(robot)
    end

    test "Visibility", %{tiles: tiles} do
      :ok =
        GenServer.call(
          AndyWorld.playground(),
          {:place_robot,
           name: :andy,
           node: node(),
           row: 5,
           column: 6,
           orientation: 90,
           sensor_data: %{},
           motor_data: %{}}
        )

      {:ok, robots} = AndyWorld.robots()
      assert {19, 5} == Space.closest_obstructed(tiles, Map.fetch!(robots, :andy), 90, robots)

      :ok =
        GenServer.call(
          AndyWorld.playground(),
          {:move_robot, name: :andy, row: 2, column: 9}
        )

      {:ok, robots} = AndyWorld.robots()
      assert {9, 16} == Space.closest_obstructed(tiles, Map.fetch!(robots, :andy), 0, robots)

      {x, y} = Space.closest_obstructed(tiles, Map.fetch!(robots, :andy), 45, robots)
      # Logger.info("Closest at 45 degrees is #{inspect({x, y})}")
      assert x > 9
      assert y > 2

      {x, y} = Space.closest_obstructed(tiles, Map.fetch!(robots, :andy), 180, robots)
      # Logger.info("Closest at 180 degrees is #{inspect({x, y})}")
      assert x = 9
      assert y < 2

      {x, y} = Space.closest_obstructed(tiles, Map.fetch!(robots, :andy), 270, robots)
      # Logger.info("Closest at 270 degrees is #{inspect({x, y})}")
      assert x < 9
      assert y = 2

      {x, y} = Space.closest_obstructed(tiles, Map.fetch!(robots, :andy), -45, robots)
      # Logger.info("Closest at -45 degrees is #{inspect({x, y})}")
      assert x < 9
      assert y = 2
    end
  end
end
