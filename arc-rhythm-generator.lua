--[[
arc rhythm generator

inspired by the max patch by stretta
https://youtu.be/HM0EBvJe1s0


pages (IDEA):
- control density
- control speed
- generate new patterns

TODO:
- add density control
- set up midi trigger generation
- add external midi clock
- add ability to generate new patterns
- add tests (? does this make sense to do ?)
- add ability to reset after n clock ticks
]]

-- there are 64 leds in each ring, so each pattern is 64 steps long.
-- TODO: come up with a data structure to weight each step (for density control).

-- tracks the playhead position for each ring.
position = { 0, 0, 0, 0 }

-- playhead spead for each ring.
speed = { 1, 1, 1, 1 }

function arc(ring, delta)
    -- adjust speed.
    -- TODO: figure out how to make these swings smaller.
    -- i tried dividing delta, but i think passing a float for speed caused issues.
    -- and using math.floor here also seemed to cause issues. maybe i need to floor elsewhere...
    speed[ring] = clamp(speed[ring] + delta, -64, 64)
end

function redraw()
    for n = 1, 4 do
        -- zero out all led levels.
        arc_led_all(n, 0)

        -- draw patterns.
        arc_led(n, position[n] + 1, 8)

        -- draw trigger markers.
        arc_led(n, 1, 15)
    end

    arc_refresh()
end

function tick()
    -- advance the trigger steps.
    -- for now, just have a single value, to figure out the advancing logic.
    -- TODO: implement patterns.
    for n = 1, 4 do
        position[n] = (position[n] + speed[n]) % 64

        -- TODO: check to see if we should emit a midi note.
    end

    redraw()
end

function init()
    print("\n arc rhythm generator")

    m = metro.new(tick, 33)
end

init()
