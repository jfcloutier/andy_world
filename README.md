# AndyWorld

A simulated world for robots running Andy

Start first (before the instances of Andy) with

    > iex --sname playground --cookie 'predictive processing' -S mix phx.server

T0 pause and resume a robot:
    AndyWorld.pause(:karl)
    AndyWorld.resume(:karl)