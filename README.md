# AndyWorld

A simulated world for robots running Andy

Start first (before the instances of Andy) with

    > iex --sname playground --cookie 'predictive processing' -S mix phx.server

To pause and resume all robots:

    > AndyWorld.pause_robots
    > AndyWorld.resume_robots