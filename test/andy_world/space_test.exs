defmodule AndyWorld.Space.Test do
  use ExUnit.Case

  alias AndyWorld.{Space, Tile}
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

  describe "Spatial awareness" do
    test "Closest obstructed", %{tiles: tiles} do
      {:ok, robot} =
        AndyWorld.place_robot(
          name: :andy,
          node: node(),
          row: 5,
          column: 6,
          orientation: 90,
          sensor_data: %{},
          motor_data: %{}
        )

      assert {19, 5} == Space.closest_obstructed(tiles, robot, 90)

      {:ok, robot} = AndyWorld.move_robot(name: :andy, row: 2, column: 9)

      assert {9, 16} == Space.closest_obstructed(tiles, robot, 0)

      {x, y} = Space.closest_obstructed(tiles, robot, 45)
      # Logger.info("Closest at 45 degrees is #{inspect({x, y})}")
      assert x > 9
      assert y > 2

      {x, y} = Space.closest_obstructed(tiles, robot, 180)
      # Logger.info("Closest at 180 degrees is #{inspect({x, y})}")
      assert x == 9
      assert y < 2

      {x, y} = Space.closest_obstructed(tiles, robot, 270)
      # Logger.info("Closest at 270 degrees is #{inspect({x, y})}")
      assert x < 9
      assert y == 2

      {x, y} = Space.closest_obstructed(tiles, robot, -90)
      # Logger.info("Closest at 270 degrees is #{inspect({x, y})}")
      assert x < 9
      assert y == 2

      {x, y} = Space.closest_obstructed(tiles, robot, -45)
      # Logger.info("Closest at -45 degrees is #{inspect({x, y})}")
      assert x < 9
      assert y > 2
    end

    test "Adjoining tile", %{tiles: tiles} do
      {:ok, %Tile{row: row, column: column}} = Space.tile_adjoining_at_angle(0, {2.5, 4.5}, tiles)
      assert row == 5
      assert column == 2

      {:ok, %Tile{row: row, column: column}} =
        Space.tile_adjoining_at_angle(90, {2.5, 4.5}, tiles)

      assert row == 4
      assert column == 3

      {:ok, %Tile{row: row, column: column}} =
        Space.tile_adjoining_at_angle(180, {2.5, 4.5}, tiles)

      assert row == 3
      assert column == 2

      {:ok, %Tile{row: row, column: column}} =
        Space.tile_adjoining_at_angle(270, {2.5, 4.5}, tiles)

      assert row == 4
      assert column == 1

      {:ok, %Tile{row: row, column: column}} =
        Space.tile_adjoining_at_angle(720, {2.5, 4.5}, tiles)

      assert row == 5
      assert column == 2
      {:error, :invalid} = Space.tile_adjoining_at_angle(180, {0, 0}, tiles)
    end

    test "Tile visibility", %{tiles: tiles} do
      {:ok, robot} =
        AndyWorld.place_robot(
          name: :andy,
          node: node(),
          row: 6,
          column: 9,
          orientation: 90,
          sensor_data: %{},
          motor_data: %{}
        )

      {:ok, tile} = Space.get_tile(tiles, row: 6, column: 11)

      assert true ==
               Space.tile_visible_to?(
                 tile,
                 robot,
                 tiles
               )

      {:ok, tile} = Space.get_tile(tiles, row: 6, column: 15)

      assert false ==
               Space.tile_visible_to?(
                 tile,
                 robot,
                 tiles
               )

      {:ok, tile} = Space.get_tile(tiles, row: 10, column: 9)

      assert true ==
               Space.tile_visible_to?(
                 tile,
                 robot,
                 tiles
               )

      {:ok, tile} = Space.get_tile(tiles, row: 6, column: 1)

      assert false ==
               Space.tile_visible_to?(
                 tile,
                 robot,
                 tiles
               )

      {:ok, tile} = Space.get_tile(tiles, row: 6, column: 2)

      assert true ==
               Space.tile_visible_to?(
                 tile,
                 robot,
                 tiles
               )

      {:ok, tile} = Space.get_tile(tiles, row: 15, column: 15)

      assert true ==
               Space.tile_visible_to?(
                 tile,
                 robot,
                 tiles
               )
    end

    test "Angle perceived" do
      assert 0 == Space.angle_perceived({0, 0}, 0, {0, 0})
      assert 45 == Space.angle_perceived({0, 0}, 0, {100, 100})
      assert 0 == Space.angle_perceived({0, 0}, 45, {100, 100})
      assert 90 == Space.angle_perceived({0, 0}, 0, {0, 100})
      assert 180 = Space.angle_perceived({100, 100}, 0, {100, 0})
      assert -135 = Space.angle_perceived({100, 100}, 0, {0, 0})
      assert 135 = Space.angle_perceived({0, 100}, 0, {100, 0})
    end
  end

  describe "Social distancing" do
    test "Closest visible robot", %{tiles: tiles} do
      {:ok, andy} =
        AndyWorld.place_robot(
          name: :andy,
          node: node(),
          row: 6,
          column: 9,
          orientation: 0,
          sensor_data: %{},
          motor_data: %{}
        )

      {:ok, _karl} =
        AndyWorld.place_robot(
          name: :karl,
          node: node(),
          row: 1,
          column: 1,
          orientation: 0,
          sensor_data: %{},
          motor_data: %{}
        )

      {:ok, _rodney} =
        AndyWorld.place_robot(
          name: :rodney,
          node: node(),
          row: 18,
          column: 18,
          orientation: 0,
          sensor_data: %{},
          motor_data: %{}
        )

      {:ok, closest_robot} = Space.closest_robot_visible_to(andy, tiles)
      assert closest_robot.name == :karl

      {:ok, _karl} = AndyWorld.move_robot(name: :karl, row: 8, column: 15)
      {:ok, closest_robot} = Space.closest_robot_visible_to(andy, tiles)
      assert closest_robot.name == :rodney
    end

    test "distance to other robot" do
      {:ok, andy} =
        AndyWorld.place_robot(
          name: :andy,
          node: node(),
          row: 6,
          column: 9,
          orientation: 0,
          sensor_data: %{},
          motor_data: %{}
        )

      {:ok, karl} =
        AndyWorld.place_robot(
          name: :karl,
          node: node(),
          row: 1,
          column: 1,
          orientation: 0,
          sensor_data: %{},
          motor_data: %{}
        )

      {:ok, rodney} =
        AndyWorld.place_robot(
          name: :rodney,
          node: node(),
          row: 18,
          column: 18,
          orientation: 0,
          sensor_data: %{},
          motor_data: %{}
        )

      assert round(Space.distance_to_other_robot(andy, karl)) == 94
      assert round(Space.distance_to_other_robot(andy, rodney)) == 150
      assert round(Space.distance_to_other_robot(karl, rodney)) == 240
    end
  end

  describe "Where's the beacon?" do
    test "Find the beacon", %{tiles: tiles} do
      tile = Space.find_beacon_tile(tiles, 1)
      assert tile.row == 17
      assert tile.column == 9
    end
  end
end
