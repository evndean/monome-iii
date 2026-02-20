--[[
test arc level

very basic experiment in setting led levels in arc.

pulling from this discussion thread: https://github.com/monome/iii/discussions/36.
that was written for the beta version of iii, so need to adjust some.
]]

local rings = { 0, 0, 0, 0 }
local responsiveness = { 1, 10, 100, 500 }
local brightness = 15
local refresh_in_ms = 12
local refresh = false

function arc(ring, delta)
    rings[ring] = clamp(rings[ring] + delta, 0, 64)
    refresh = true
end

local function redraw()
    if refresh then
        for ring = 1, 4 do
            arc_led_all(ring, 0)
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
        arc_led_all(ring, 0)
        arc_res(ring, responsiveness[ring])
    end
    arc_refresh()
end

setup()

metro.new(redraw, refresh_in_ms)
