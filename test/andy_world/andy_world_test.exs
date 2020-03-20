defmodule AndyWorld.Test do
  use ExUnit.Case

  alias AndyWorld.Space

  setup_all do
    {:ok, tiles} = AndyWorld.tiles()
    default_color = Application.get_env(:andy_world, :default_color)
    default_ambient = Application.get_env(:andy_world, :default_ambient)
    {:ok, %{tiles: tiles, tile_defaults: %{color: default_color, ambient: default_ambient}}}
  end

  describe "Tiles" do
    test "Tile ordering", %{tiles: tiles} do
      [[first_tile | _] | _] = tiles
      assert first_tile.row == 0
      assert first_tile.column == 0
    end

    test "Tile properties", %{tiles: tiles, tile_defaults: tile_defaults} do
      {:ok, tile} = Space.get_tile(tiles, 2, 9)
      assert tile.beacon_orientation == "S"
      assert tile.obstacle_height == 10
      assert tile.ground_color == tile_defaults.color
      assert tile.ambient_light == tile_defaults.ambient
    end
  end

  describe "Robots" do
    test "Placing a robot", %{tiles: tiles} do
      :ok = GenServer.call(AndyWorld.playground, {:place_robot, :andy, node(), 5, 6, 90, %{}, %{}})
      {:ok, %{andy: andy} = robots} = AndyWorld.robots()
      assert andy.name == :andy
      assert andy.x == 5.5
      assert andy.y == 6.5
      assert Space.occupied?(5, 6, tiles, robots) == true
    end

    test "Visibility", %{tiles: tiles} do
      :ok = GenServer.call(AndyWorld.playground, {:place_robot, :andy, node(), 5, 6, 90, %{}, %{}})
      {:ok, robots} = AndyWorld.robots()
      assert Space.closest_obstructed(tiles, 0, 0, 90, robots) == {0, 19}
    end
  end
end
