# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :andy_world,
  default_ambient: 10,
  default_color: 7,
  max_events_remembered: 1,
  tile_side_cm: 10,
  tiles_per_rotation: 0.5,
  degrees_per_motor_rotation: 45,
  tiles_per_motor_rotation: 0.5,
  # "<obstacle height * 10><beacon orientation><color><ambient * 10>|...."
  # _ = default, otherwise: obstacle in 0..9,  color in 0..7, ambient in 0..9, beacon in [N, S, E, W]
  playground_tiles: [
    "____|____|____|____|____|____|____|____|1___|1___|1___|____|____|____|____|____|____|____|____|____",
    "____|____|____|____|____|____|____|____|1___|1___|1___|____|____|____|____|____|____|____|____|____",
    "____|____|____|____|____|____|____|____|1___|1S__|1___|____|____|____|____|____|____|____|____|____",
    "____|____|____|____|____|____|____|____|__6_|__6_|__6_|____|____|____|____|____|____|____|____|____",
    "____|____|____|____|____|____|____|____|__6_|__6_|__6_|____|____|____|____|____|____|____|____|____",
    "____|____|____|____|____|____|____|____|__6_|__6_|__6_|____|____|____|____|____|____|____|____|____",
    "____|____|____|____|____|____|____|____|____|____|____|____|____|____|____|____|____|____|____|___1",
    "____|____|____|____|____|____|____|____|____|____|____|____|____|____|____|____|____|____|___1|___1",
    "____|____|____|____|____|____|____|____|____|____|____|____|____|____|____|____|____|___1|___1|___1",
    "____|____|3___|____|____|____|____|____|____|____|____|____|____|____|____|____|____|___1|___1|___1",
    "____|____|3___|____|____|____|____|____|____|____|____|____|____|3___|3___|____|____|____|___1|___1",
    "____|____|3___|____|____|____|____|____|____|____|____|____|____|____|3___|____|____|____|____|___1",
    "____|____|3___|____|____|____|____|____|____|____|____|____|____|____|3___|____|____|____|____|____",
    "____|____|3___|____|____|____|____|____|____|____|____|____|____|____|3___|____|____|____|____|____",
    "____|____|____|____|____|____|____|____|____|____|____|____|____|____|____|____|____|____|____|____",
    "____|____|____|____|____|____|____|____|____|____|____|____|____|____|____|____|____|____|____|____",
    "____|____|____|____|____|____|____|____|____|____|____|____|____|____|____|____|____|____|____|____",
    "____|____|____|____|____|____|____|____|____|____|____|____|____|____|____|____|____|____|____|____",
    "____|____|____|____|____|____|____|____|____|____|____|____|____|____|____|____|____|____|____|____",
    "____|____|____|____|____|____|____|____|____|____|____|____|____|____|____|____|____|____|____|____"
    # ^--row 0, column 0
  ]

# Configures the endpoint
config :andy_world, AndyWorldWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "CRVSo1ld+c+h6bTDVOXMERlRxYKR7+H56IWjXGz1wHYAXw1wwwmBFJAr549i17ya",
  render_errors: [view: AndyWorldWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: AndyWorld.PubSub, adapter: Phoenix.PubSub.PG2],
  live_view: [
    signing_salt: "SECRET_SALT"
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
