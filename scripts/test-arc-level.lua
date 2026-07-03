--[[
test arc level

very basic experiment in setting led levels in arc.
turn the dials to change the number of leds turned on.

pulling from this discussion thread: https://github.com/monome/iii/discussions/36.
that was written for the beta version of iii, so need to adjust some.
]]

local rings = { 0, 0, 0, 0 }
-- 17 feels pretty close to matching the knob spin rate.
local responsiveness = { 1, 17, 50, 100 }
local brightness = 15
local refresh_rate = 0.012 -- 12 ms
local refresh = false

function event_arc(ring, delta)
    rings[ring] = clamp(rings[ring] + delta, 0, 64)
    refresh = true
end

local function redraw()
    if refresh then
        for ring = 1, 4 do
            arc_led_ring(ring, 0)
            for led = 1, rings[ring] do
                arc_led(ring, led, brightness)
            end
        end
        arc_refresh()
        refresh = false
    end
end

local function setup()
    for ring = 1, 4 do
        arc_led_ring(ring, 0)
        arc_res(ring, responsiveness[ring])
    end
    arc_refresh()
end

setup()

local m = metro.init(redraw, refresh_rate)
m:start()
