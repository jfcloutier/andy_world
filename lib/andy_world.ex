defmodule AndyWorld do
  @moduledoc """
  AndyWorld provides a virtual playground for simulated robots
  """

  def playground() do
    :global.whereis_name(:andy_world)
  end

  def tiles() do
    GenServer.call(playground(), :tiles)
  end

  def robots() do
    GenServer.call(playground(), :robots)
  end

  def clear_robots() do
    GenServer.call(playground(), :clear_robots)
  end
end
