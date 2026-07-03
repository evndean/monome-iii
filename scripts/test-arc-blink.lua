--[[
test arc blink

turn the dials to adjust the blink rate.

fairly simple approach.
record the last time we turned the leds on, then compare against current time.
]]

local blink_rate_ms = { 1000, 1000, 1000, 1000 }
local is_on = { false, false, false, false }
local last_on_ts = { 0, 0, 0, 0 }
local brightness = 15
local refresh_rate_ms = 12
local refresh = false

function arc(ring, delta)
    -- clockwise --> faster
    blink_rate_ms[ring] = clamp(blink_rate_ms[ring] - delta * 10, 20, 5000)
end

local function check_blink()
    local t = get_time()
    for ring = 1, 4 do
        if is_on[ring] then
            if t - last_on_ts[ring] > blink_rate_ms[ring] / 2 then
                is_on[ring] = false
                refresh = true
            end
        else
            if t - last_on_ts[ring] > blink_rate_ms[ring] then
                last_on_ts[ring] = t
                is_on[ring] = true
                refresh = true
            end
        end
    end
end

local function redraw()
    if refresh then
        for ring = 1, 4 do
            arc_led_all(ring, is_on[ring] and brightness or 0)
        end
        refresh = false
    end
    arc_refresh()
end

local function setup()
    for ring = 1, 4 do
        arc_led_all(ring, 0)
        -- arc_res(ring, 50)
    end
    arc_refresh()
end

setup()

metro.new(check_blink, refresh_rate_ms)
metro.new(redraw, refresh_rate_ms)
