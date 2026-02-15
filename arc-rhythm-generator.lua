--[[
arc rhythm generator

inspired by the max patch by stretta
https://youtu.be/HM0EBvJe1s0

TODO:
- add tests (? does this make sense to do ?)
- add ability to reset after n clock ticks
]]

-- TODO: make this configurable from the arc.
local TEMPO_BPM = 120

local modetext = { "speed", "density", "pattern_gen" }
local mode = 1

-- tracks the playhead position for each ring.
local position = { 0, 0, 0, 0 }

-- playhead spead for each ring.
local speed = { 1, 1, 1, 1 }
local MAX_SPEED = 64

-- density control for each ring.
local density = { 1, 1, 1, 1 }
local MAX_DENSITY = 512

-- used to tell when a given ring should emit a midi note on the next beat.
local midi_should_emit = { false, false, false, false }
local midi_sent_on_last_tick = { false, false, false, false }
-- TODO: make this configurable from the arc.
local midi_channels = { 1, 1, 1, 1 }
-- TODO: make this configurable from the arc.
local midi_notes = { 53, 58, 61, 63 }

-- patterns for each ring.
local patterns = { {}, {}, {}, {} }

function arc(ring, delta)
    if mode == 1 then
        -- TODO: figure out how to make these swings smaller.
        -- i tried dividing delta, but i think passing a float for speed caused issues.
        -- and using math.floor here also seemed to cause issues. maybe i need to floor elsewhere...
        speed[ring] = clamp(speed[ring] + delta, -MAX_SPEED, MAX_SPEED)
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
        mode = wrap(mode + 1, 1, #modetext)
        ps("mode: %i: %s", mode, modetext[mode])
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
            local led = wrap(step + position[ring], 1, 64)
            arc_led(ring, led, is_active == true and 8 or 0)
        end

        -- draw trigger markers.
        arc_led(ring, 1, 15)
    end

    arc_refresh()
end

function pattern_tick()
    -- advance the trigger steps.
    for ring = 1, 4 do
        local new_position = wrap(position[ring] + speed[ring], 1, #patterns[ring])
        position[ring] = new_position

        -- check to see if we should emit a midi note.
        local should_trigger = patterns[ring][new_position] <= density[ring]
        if should_trigger == true then
            midi_should_emit[ring] = true
        end
    end

    redraw()
end

function tempo_tick()
    -- turn off notes from previous tick.
    for ring = 1, 4 do
        if midi_sent_on_last_tick[ring] == true then
            midi_note_off(midi_notes[ring], 127, midi_channels[ring])
            midi_sent_on_last_tick[ring] = false
        end
    end

    -- send new midi notes.
    for ring = 1, 4 do
        if midi_should_emit[ring] == true then
            ps("emitting note for ring %d", ring)
            midi_note_on(midi_notes[ring], 127, midi_channels[ring])
            midi_sent_on_last_tick[ring] = true
            midi_should_emit[ring] = false
        end
    end
end

function init()
    print("\n arc rhythm generator")

    -- initialize patterns. there are 64 leds in each ring, so make each pattern 64 steps long to start.
    for n = 1, 4 do
        patterns[n] = pattern_gen(64, MAX_DENSITY)
    end

    local pt = metro.new(pattern_tick, 33)

    -- TODO: implement external midi clock; if enabled, disable this.
    local tt = metro.new(tempo_tick, math.floor(60000 / TEMPO_BPM))
end

init()
