--[[
test arc blink

turn the dials to adjust the blink rate.

fairly simple approach.
record the last time we turned the leds on, then compare against current time.
]]

local blink_rate = {1, 1, 1, 1}
local is_on = { false, false, false, false }
local last_on_ts = { 0, 0, 0, 0 }
local brightness = 15
local refresh_rate = 0.012 -- 12 ms
local refresh = false

function event_arc(ring, delta)
    -- clockwise --> faster
    -- clamp between 20 ms and 5 s
    blink_rate[ring] = clamp(blink_rate[ring] - delta / 1000, 0.020, 5)
end

local function check_blink()
    local t = get_time()
    for ring = 1, 4 do
        if is_on[ring] then
            if t - last_on_ts[ring] > blink_rate[ring] / 2 then
                is_on[ring] = false
                refresh = true
            end
        else
            if t - last_on_ts[ring] > blink_rate[ring] then
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
            arc_led_ring(ring, is_on[ring] and brightness or 0)
        end
        refresh = false
    end
    arc_refresh()
end

local function setup()
    -- reset arc resolution
    for ring = 1, 4 do
        arc_res(ring, 1)
    end

    -- reset arc LED levels
    arc_led_all(0)
    arc_refresh()
end

setup()

local m_check = metro.init(check_blink, refresh_rate)
local m_redraw = metro.init(redraw, refresh_rate)
m_check:start()
m_redraw:start()
