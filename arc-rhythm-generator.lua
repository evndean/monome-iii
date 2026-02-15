--[[
arc rhythm generator

inspired by the max patch by stretta
https://youtu.be/HM0EBvJe1s0

TODO:
- set up midi trigger generation
- add external midi clock
- add tests (? does this make sense to do ?)
- add ability to reset after n clock ticks
]]

local modetext = { "speed", "density", "pattern_gen" }
local mode = 1

-- tracks the playhead position for each ring.
local position = { 0, 0, 0, 0 }

-- playhead spead for each ring.
local speed = { 1, 1, 1, 1 }

-- density control for each ring.
local density = { 1, 1, 1, 1 }
local MAX_DENSITY = 512

-- patterns for each ring.
local patterns = { {}, {}, {}, {} }

function arc(ring, delta)
    if mode == 1 then
        -- TODO: figure out how to make these swings smaller.
        -- i tried dividing delta, but i think passing a float for speed caused issues.
        -- and using math.floor here also seemed to cause issues. maybe i need to floor elsewhere...
        speed[ring] = clamp(speed[ring] + delta, -64, 64)
        ps("speed %d: %d", ring, speed[ring])
    elseif mode == 2 then
        density[ring] = clamp(density[ring] + delta, 0, MAX_DENSITY)
        ps("density %d: %d", ring, density[ring])
    elseif mode == 3 then
        -- TODO: debouce this, so we generate patterns less frequently (controls are very sensitive).
        patterns[ring] = pattern_gen(64, MAX_DENSITY)
        ps("generated new pattern for ring %d", ring)
    end
end

function arc_key(z)
    if z == 1 then
        mode = mode % #modetext + 1
        ps("mode: %i %s", mode, modetext[mode])
    end
end

-- each step in a pattern is a density value, from 1 to max_density.
-- a step with a value of 1 will always trigger.
function pattern_gen(len, max_density)
    p = {}
    -- have the first note always trigger.
    p[1] = 1
    -- randomly assign density for remaining notes.
    -- TODO: come up with a more musical approach?
    for i = 2, len do
        p[i] = math.floor(math.random(2, max_density))
    end
    return p
end

function redraw()
    -- TODO: different UX for different modes
    for ring = 1, 4 do
        -- zero out all led levels.
        arc_led_all(ring, 0)

        -- draw patterns.
        local pattern = patterns[ring]
        for step = 1, #pattern do
            local is_active = patterns[ring][step] <= density[ring]
            local led = (step + position[ring] - 1) % 64 + 1
            arc_led(ring, led, is_active == true and 8 or 0)
        end

        -- draw trigger markers.
        arc_led(ring, 1, 15)
    end

    arc_refresh()
end

function tick()
    -- advance the trigger steps.
    for n = 1, 4 do
        position[n] = (position[n] + speed[n]) % 64

        -- TODO: check to see if we should emit a midi note.
    end

    redraw()
end

function init()
    print("\n arc rhythm generator")

    -- initialize patterns. there are 64 leds in each ring, so each pattern is 64 steps long.
    for n = 1, 4 do
        patterns[n] = pattern_gen(64, MAX_DENSITY)
    end

    m = metro.new(tick, 33)
end

init()
