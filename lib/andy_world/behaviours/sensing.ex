defmodule AndyWorld.Sensing do
  @moduledoc "The sensing behaviour"

  alias AndyWorld.{Sensing.Sensor, Tile, Robot}

  @callback sensed(
              robot :: %Robot{},
              sensor :: %Sensor{},
              sense :: atom,
              tile :: %Tile{},
              tiles :: [%Tile{}]
            ) :: any
end
