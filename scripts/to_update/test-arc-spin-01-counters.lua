--[[
test arc spin

very basic experiment in rotating leds.
turn the dials to adjust the speed of rotation.

note: because we're using counts + modular arithmetic, we can't ever reverse direction.
in practice, we probably don't want this; it seems pretty limiting.
]]

local pos = { 1, 1, 1, 1 }
local speed = { 1, 1, 1, 1 } -- num ticks needed before advancing
local count = { 0, 0, 0, 0 }
local responsiveness = { 1, 10, 100, 500 }
local brightness = 15
local refresh_in_ms = 12
local refresh = false

function arc(ring, delta)
    speed[ring] = clamp(speed[ring] - delta, 1, 64)
end

local function step_advance()
    for ring = 1, 4 do
        count[ring] = count[ring] + 1
        if count[ring] % speed[ring] == 0 then
            pos[ring] = wrap(pos[ring] + 1, 1, 64)
            refresh = true
        end
    end
end

local function redraw()
    if refresh then
        for ring = 1, 4 do
            arc_led_all(ring, 0)
            arc_led(ring, pos[ring], brightness)
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

metro.new(step_advance, refresh_in_ms)
metro.new(redraw, refresh_in_ms)
