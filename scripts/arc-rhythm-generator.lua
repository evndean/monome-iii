--[[
arc rhythm generator

inspired by the max patch by stretta
https://youtu.be/HM0EBvJe1s0

TODO:
- add tests (? does this make sense to do ?)
- add ability to reset after n clock ticks
]]

-- TODO: implement external midi clock (will need to disable internal midi clock)
--   Not totally sure how to go about this, and it seems helpers for this are planned;
--   https://github.com/monome/iii/discussions/23#discussion-8188837

local tempo_bpm = 120
local MIN_BPM = 40
local MAX_BPM = 240
local tempo_changed_on_last_tick = false

local refresh_rate_ms = 15
local needs_redraw = false

-- #### mode-specific variables ####

local mode = 1
local mode_name = { "speed", "density", "pattern_gen", "midi_notes", "midi_channels", "clock" } -- TODO split modes into two pages: "perform" and "config"
local mode_responsiveness = { 20, 5, 100, 50, 50, 50 }

-- #### ring-specific variables ####

local ring_positions = { 1, 1, 1, 1 }
local ring_speeds = { 1, 1, 1, 1 } -- TODO: see if we can make speed 1 slower (i.e. decouple redraw from step progression?)
local MAX_SPEED = 16
local ring_densities = { 1, 1, 1, 1 }
local MAX_DENSITY = 512
local ring_patterns = { {}, {}, {}, {} }
local ring_midi_should_emit = { false, false, false, false }
local ring_midi_sent_on_last_tick = { false, false, false, false }
local ring_midi_channels = { 1, 1, 1, 1 }
local ring_midi_notes = { 53, 58, 61, 63 }

-- ####

function arc(ring, delta)
    if mode == 1 then
        ring_speeds[ring] = clamp(ring_speeds[ring] + delta, -MAX_SPEED, MAX_SPEED)
        ps("set speed for ring: %d: %d", ring, ring_speeds[ring])
    elseif mode == 2 then
        ring_densities[ring] = clamp(ring_densities[ring] + delta, 0, MAX_DENSITY)
        ps("set density for ring: %d: %d", ring, ring_densities[ring])
    elseif mode == 3 then
        ring_patterns[ring] = pattern_gen(64, MAX_DENSITY)
        ps("generated new pattern for ring: %d", ring)
    elseif mode == 4 then
        ring_midi_notes[ring] = clamp(ring_midi_notes[ring] + delta, 0, 127)
        ps("set midi note for ring: %d: %d", ring, ring_midi_notes[ring])
    elseif mode == 5 then
        ring_midi_channels[ring] = clamp(ring_midi_channels[ring] + delta, 1, 16)
        ps("set midi channel for ring: %d: %d", ring, ring_midi_channels[ring])
    elseif mode == 6 then
        -- clock is a bit different; for now, only ring 1 does anything
        if ring == 1 then
            tempo_bpm = clamp(tempo_bpm + delta, MIN_BPM, MAX_BPM)
            tempo_changed_on_last_tick = true
            ps("set tempo for ring: %d: %d", ring, tempo_bpm)
        end
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

--- Call arc_led for a block of consecutive LEDs, beginning at `start`.
---@param ring integer 1-4
---@param start integer 1-64
---@param width integer 1-64
---@param level integer 1-15
function draw_segment(ring, start, width, level)
    for i = 1, width do
        arc_led(ring, wrap(start + i - 1, 1, 64), level)
    end
end

--- Renders a 12-step piano-style display, with the active note highlighted.
---@param ring integer 1-4
---@param active_midi_note integer 0-127
function draw_piano(ring, active_midi_note)
    -- C, C#, D, D#, E, F, F#, G, G#, A, A#, B
    local IS_WHITE_KEY = { 1, 0, 1, 0, 1, 1, 0, 1, 0, 1, 0, 1 }
    local KEY_WIDTH = 3 -- must be <= 5, since 64 / 12 = 5.3333...

    --- Converts MIDI note value to 12-step note value (C=1, C#=2, D=3, etc.).
    --- MIDI note values start with C=0, but we are 1-indexing midi notes in this function.
    ---@param midi_note integer 0-127
    ---@return integer 1-12
    local function from_midi_note(midi_note)
        return wrap(midi_note + 1, 1, 12)
    end

    --- Picks the starting LED for drawing segments.
    ---@param note integer (C=1, C#=2, D=3, D#=4, etc; note that this doesn't quite align with MIDI note values, where C1=0)
    ---@return integer 1-64
    local function note_segment_start(note)
        local start = (wrap(note, 1, 12) - 1) * KEY_WIDTH + 1
        local offset = 6 * KEY_WIDTH -- so center of keyboard is at the top of the ring.
        return wrap(start - offset, 1, 64)
    end

    -- set background level
    arc_led_all(ring, 0)

    -- draw keys
    for i = 1, 12 do
        local level = IS_WHITE_KEY[i] == 1 and 2 or 0
        draw_segment(ring, note_segment_start(i), KEY_WIDTH, level)
    end

    -- highlight active note
    draw_segment(ring, note_segment_start(from_midi_note(active_midi_note)), KEY_WIDTH, 15)

    -- draw octave indicator
    -- assuming max key_width is 5, we have at least 4 spare LEDs to play with (5 * 12 = 60).
    -- TODO maybe come up with a different approach here; this feels a little too subtle.
    local octave_level = math.floor(active_midi_note / 12) -- 127 / 12 = 10.58
    draw_segment(ring, 32, 2, octave_level)
end

function draw_midi_notes_mode()
    for ring = 1, 4 do
        draw_piano(ring, ring_midi_notes[ring])
    end
end

function draw_midi_channels_mode()
    for ring = 1, 4 do
        -- valid values for channel are 1-16
        -- 64 / 16 = 4
        local step_width = 4

        -- set background level
        arc_led_all(ring, 0)

        -- show active channel
        local active_channel = ring_midi_channels[ring]
        for i = 1, active_channel do
            for j = 1, step_width do
                local led = (i - 1) * step_width + j
                arc_led(ring, led, 4)
            end
        end
    end
end

--- Draws a pattern, with an indicator for a trigger point, and all steps in the pattern.
---@param background_level integer 0-15
---@param trigger_level integer 0-15
---@param pattern_level integer 0-15
function draw_patterns_mode(background_level, trigger_level, pattern_level)
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

--- Draws a level indicator.
---@param ring integer 1-4
---@param val integer
---@param min_val integer
---@param max_val integer
function draw_level(ring, val, min_val, max_val)
    arc_led_all(ring, 0)

    local level = linlin(min_val, max_val, 1, 64, val)
    local last_full_strength_led = math.floor(level)
    local next_led_level = math.floor(linlin(0, 1, 0, 15, level % 1))

    for led = 1, last_full_strength_led do
        arc_led(ring, led, 15)
    end
    if last_full_strength_led ~= 64 then
        arc_led(ring, last_full_strength_led + 1, next_led_level)
    end
end

function draw_clock_mode()
    for ring = 1, 4 do
        arc_led_all(ring, 0)
    end

    draw_level(1, tempo_bpm, MIN_BPM, MAX_BPM)
end

function redraw()
    if mode == 1 then
        draw_patterns_mode(0, 12, 4)
    elseif mode == 2 then
        draw_patterns_mode(0, 2, 8)
    elseif mode == 3 then
        draw_patterns_mode(1, 1, 8)
    elseif mode == 4 then
        draw_midi_notes_mode()
    elseif mode == 5 then
        draw_midi_channels_mode()
    elseif mode == 6 then
        draw_clock_mode()
    end

    arc_refresh()

    needs_redraw = false
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

    needs_redraw = true
end

local function maybe_send_midi_notes()
    -- turn off notes sent on last call.
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

--- Calculates the number of milliseconds for a single 16th-note.
---@param bpm integer
---@return integer
local function bpm_to_ms(bpm)
    -- ms/second * seconds/minute * minutes/beat * beat/steps --> ms/step
    return math.floor(1000 * 60 / bpm / 16)
end

local function tick_redraw()
    if needs_redraw then
        redraw()
    end
end

local metro_tempo
local function tick_tempo()
    -- resolution isn't great as we get into higher BPMs...
    -- TODO find a way to address this?
    if tempo_changed_on_last_tick then
        tempo_changed_on_last_tick = false
        metro.stop(metro_tempo)
        ps("new tempo ms: %d", bpm_to_ms(tempo_bpm))
        metro_tempo = metro.new(tick_tempo, bpm_to_ms(tempo_bpm))
    end

    maybe_send_midi_notes()
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

    metro.new(tick_redraw, refresh_rate_ms)
    metro_tempo = metro.new(tick_tempo, bpm_to_ms(tempo_bpm))
end

init()
