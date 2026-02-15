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
- add speed control
- set up midi trigger generation
- add external midi clock
- add ability to generate new patterns
- add tests (? does this make sense to do ?)
- add ability to reset after n clock ticks
]]

-- there are 64 leds in each ring, so each pattern is 64 steps long.
-- TODO: come up with a data structure to weight each step (for density control).

-- tracks the playhead position for each ring.
position = {0,0,0,0}

function redraw()
    for n=1,4 do
        -- zero out all led levels.
        arc_led_all(n,0)

        -- draw patterns.
        arc_led(n, position[n], 8)

        -- draw trigger markers.
        arc_led(n, 1, 15)
    end

    arc_refresh()
end

function tick()
    -- advance the trigger steps.
    -- for now, just have a single value, to figure out the advancing logic.
    -- TODO: implement patterns.
    -- TODO: make the speed variable per ring.
    for n=1,4 do
        position[n] = position[n] % 64 + 1

        -- TODO: check to see if we should emit a midi note.
    end

    redraw()
end

function init()
    print("\n arc rhythm generator")

    m = metro.new(tick, 33)
end

init()