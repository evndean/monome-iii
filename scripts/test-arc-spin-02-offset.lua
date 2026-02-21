--[[
test arc spin

very basic experiment in rotating leds.
using floats for offset and speed.

]]

local offset = { 1, 1, 1, 1 }        -- float; where we are in a given tick.
local speed = { 0.5, 0.5, 0.5, 0.5 } -- float; how far to advance per tick.
local max_speed = 4
local brightness = 15
local refresh_rate_ms = 12
local refresh = false

function arc(ring, delta)
    speed[ring] = clamp(speed[ring] + delta / 32, -max_speed, max_speed)
end

local function step_advance()
    for ring = 1, 4 do
        local last_int = math.floor(offset[ring])
        offset[ring] = wrap(offset[ring] + speed[ring], 1, 64)
        local next_int = math.floor(offset[ring])
        if last_int ~= next_int then
            refresh = true
        end
    end
end

local function redraw()
    if refresh then
        for ring = 1, 4 do
            arc_led_all(ring, 0)
            arc_led(ring, math.floor(offset[ring]), brightness)
        end
        arc_refresh()
        refresh = false
    end
end

local function setup()
    for ring = 1, 4 do
        arc_led_all(ring, 0)
        arc_res(ring, 50)
    end
    arc_refresh()
end

setup()

metro.new(step_advance, refresh_rate_ms)
metro.new(redraw, refresh_rate_ms)
