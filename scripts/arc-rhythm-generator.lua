--[[
arc rhythm generator

inspired by the max patch by stretta
https://youtu.be/HM0EBvJe1s0

TODO:
- add tests (? does this make sense to do ?)
- add ability to reset after n clock ticks
]]

-- TODO: make this configurable from the arc.
-- TODO: implement external midi clock (will need to disable internal midi clock)
local TEMPO_BPM = 120

local mode = 1
local mode_name = { "speed", "density", "pattern_gen" }
local mode_responsiveness = { 20, 5, 25 }

-- tracks the playhead position for each ring.
local positions = { 1, 1, 1, 1 }

-- playhead spead for each ring.
local speeds = { 1, 1, 1, 1 }
local MAX_SPEED = 16

-- density control for each ring.
local densities = { 1, 1, 1, 1 }
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
        speeds[ring] = clamp(speeds[ring] + delta, -MAX_SPEED, MAX_SPEED)
        ps("speed %d: %d", ring, speeds[ring])
    elseif mode == 2 then
        densities[ring] = clamp(densities[ring] + delta, 0, MAX_DENSITY)
        ps("density %d: %d", ring, densities[ring])
    elseif mode == 3 then
        patterns[ring] = pattern_gen(64, MAX_DENSITY)
        ps("generated new pattern for ring %d", ring)
    end
end

function arc_key(z)
    if z == 1 then
        mode = wrap(mode + 1, 1, #mode_name)
        ps("mode: %i: %s", mode, mode_name[mode])

        -- set sensitivity based on mode
        for ring = 1, 4 do
            arc_res(ring, mode_responsiveness[mode])
        end
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
        for step = 1, #patterns[ring] do
            local is_active = patterns[ring][step] <= densities[ring]
            local led = wrap(step + positions[ring] - 1, 1, 64)
            arc_led(ring, led, is_active == true and 4 or 0)
        end

        -- draw trigger markers.
        arc_led(ring, 1, 8)
    end

    arc_refresh()
end

function pattern_tick()
    for ring = 1, 4 do
        -- check if any of the notes we're about to pass through should trigger a note on event.
        for i = 1, speeds[ring] do
            if patterns[ring][wrap(positions[ring] + i, 1, #patterns[ring])] <= densities[ring] then
                midi_should_emit[ring] = true
            end
        end

        -- advance the position.
        positions[ring] = wrap(positions[ring] + speeds[ring], 1, #patterns[ring])
    end

    redraw()
end

function tempo_tick()
    print("tempo tick")

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

    -- set sensitivity based on mode
    for ring = 1, 4 do
        arc_res(ring, mode_responsiveness[mode])
    end

    local pt = metro.new(pattern_tick, 33)

    local sixteenth_note_ms = math.floor(60000 / (TEMPO_BPM * 4))
    local tt = metro.new(tempo_tick, sixteenth_note_ms)
end

init()
