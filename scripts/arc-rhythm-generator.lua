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
local mode_name = { "speed", "density", "pattern_gen", "midi_notes" }
local mode_responsiveness = { 20, 5, 25, 20 }

local ring_positions = { 1, 1, 1, 1 }
local ring_speeds = { 1, 1, 1, 1 } -- TODO: see if we can make speed 1 slower (i.e. decouple redraw from step progression?)
local MAX_SPEED = 16
local ring_densities = { 1, 1, 1, 1 }
local MAX_DENSITY = 512
local ring_patterns = { {}, {}, {}, {} }
local ring_midi_should_emit = { false, false, false, false }
local ring_midi_sent_on_last_tick = { false, false, false, false }
local ring_midi_channels = { 1, 1, 1, 1 } -- TODO: make this configurable from the arc.
local ring_midi_notes = { 53, 58, 61, 63 }


function arc(ring, delta)
    if mode == 1 then
        ring_speeds[ring] = clamp(ring_speeds[ring] + delta, -MAX_SPEED, MAX_SPEED)
        ps("speed %d: %d", ring, ring_speeds[ring])
    elseif mode == 2 then
        ring_densities[ring] = clamp(ring_densities[ring] + delta, 0, MAX_DENSITY)
        ps("density %d: %d", ring, ring_densities[ring])
    elseif mode == 3 then
        ring_patterns[ring] = pattern_gen(64, MAX_DENSITY)
        ps("generated new pattern for ring %d", ring)
    elseif mode == 4 then
        ring_midi_notes[ring] = clamp(ring_midi_notes[ring] + delta, 0, 127)
        ps("set midi note for ring %d: %d", ring, ring_midi_notes[ring])
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

--- Renders a 12-step piano-style display, with the active note highlighted.
---@param ring integer 1-4
---@param active integer 0-127
function draw_piano(ring, active)
    -- TODO different levels depending on octave?
    -- TODO maybe offset so C isn't at the top?
    -- TODO figure out what to do with the extra space...

    -- 64 LEDs / 12 steps = 5.3333
    -- 5 * 12 = 60 (so we have 4 spare LEDs to play with...)

    -- 0 = C1, 127 = G9
    -- C, C#, D, D#, E, F, F#, G, G#, A, A#, B
    local is_white_key = { 1, 0, 1, 0, 1, 1, 0, 1, 0, 1, 0, 1 }
    local key_width = 5

    -- set background level
    arc_led_all(ring, 0)

    -- draw keys
    for i = 1, 12 do
        for j = 1, key_width do
            local led = (i - 1) * key_width + j
            local level = is_white_key[i] == 1 and 2 or 0
            arc_led(ring, led, level)
        end
    end

    -- highlight active note
    local active_note = wrap((active + 1), 1, 12) -- C=1, C#=2, D=3, etc...
    for i = 1, key_width do
        local led = (active_note - 1) * key_width + i
        arc_led(ring, led, 15)
    end
end

function draw_midi_channel_mode()
    for ring = 1, 4 do
        draw_piano(ring, ring_midi_notes[ring])
    end
end

function draw_pattern_mode(background_level, trigger_level, pattern_level)
    for ring = 1, 4 do
        -- set background level
        arc_led_all(ring, background_level)

        -- draw patterns.
        for step = 1, #ring_patterns[ring] do
            local is_active = ring_patterns[ring][step] <= ring_densities[ring]
            if is_active then
                local led = wrap(step + ring_positions[ring] - 1, 1, 64)
                arc_led(ring, led, pattern_level)
            end
        end

        -- draw trigger markers.
        arc_led(ring, 1, trigger_level)
    end
end

function redraw()
    if mode == 1 then
        draw_pattern_mode(0, 8, 4)
    elseif mode == 2 then
        draw_pattern_mode(0, 2, 8)
    elseif mode == 3 then
        draw_pattern_mode(2, 0, 8)
    elseif mode == 4 then
        draw_midi_channel_mode()
    end

    arc_refresh()
end

function pattern_tick()
    for ring = 1, 4 do
        -- check if any of the notes we're about to pass through should trigger a note on event.
        for i = 1, ring_speeds[ring] do
            if ring_patterns[ring][wrap(ring_positions[ring] + i, 1, #ring_patterns[ring])] <= ring_densities[ring] then
                ring_midi_should_emit[ring] = true
            end
        end

        -- advance the position.
        ring_positions[ring] = wrap(ring_positions[ring] + ring_speeds[ring], 1, #ring_patterns[ring])
    end

    redraw()
end

function tempo_tick()
    print("tempo tick")

    -- turn off notes from previous tick.
    for ring = 1, 4 do
        if ring_midi_sent_on_last_tick[ring] == true then
            midi_note_off(ring_midi_notes[ring], 127, ring_midi_channels[ring])
            ring_midi_sent_on_last_tick[ring] = false
        end
    end

    -- send new midi notes.
    for ring = 1, 4 do
        if ring_midi_should_emit[ring] == true then
            ps("emitting note for ring %d", ring)
            midi_note_on(ring_midi_notes[ring], 127, ring_midi_channels[ring])
            ring_midi_sent_on_last_tick[ring] = true
            ring_midi_should_emit[ring] = false
        end
    end
end

function init()
    print("\n arc rhythm generator")

    -- initialize patterns. there are 64 leds in each ring, so make each pattern 64 steps long to start.
    for n = 1, 4 do
        ring_patterns[n] = pattern_gen(64, MAX_DENSITY)
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
