defmodule AndyWorld.Sensing do
  @moduledoc "The sensing behaviour"

  alias AndyWorld.{Sensing.Sensor, Tile, Robot}

  @callback sense(
              robot :: %Robot{},
              sensor :: %Sensor{},
              sense :: atom | {atom, any},
              tile :: %Tile{},
              tiles :: [%Tile{}],
              robots :: map
            ) :: any
end
