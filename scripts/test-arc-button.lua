--[[
basic script to test some button functionality.

- single-click should toggle between states.
- double-click should toggle between meta states.
- long press should be its own state, return to previous state when done.
]]

local meta = 0
local mode = 0
local held = false
local double_click_ms = 200
local long_press_ms = 500
local refresh_rate_ms = 12
local refresh = false

--[[
#### single click
]]

local function handle_single_click(z)
    ps("z == %d", z)
    if z == 0 then
    elseif z == 1 then
        mode = wrap(mode + 1, 0, 1)
        refresh = true
    end
end

--[[
#### double click
]]

-- i tried defining this inside the function but it didn't seem to work.
local double_click_metro

local function double_click_key_timer()
    ps("[%d] single click", get_time())
    mode = wrap(mode + 1, 0, 1)
    metro.stop(double_click_metro)
    double_click_metro = nil
    refresh = true
end

local function handle_double_click(z)
    if z == 1 then
        if double_click_metro == nil then
            double_click_metro = metro.new(double_click_key_timer, double_click_ms, 1)
        else
            ps("[%d] double click", get_time())
            metro.stop(double_click_metro)
            double_click_metro = nil
            meta = wrap(meta + 1, 0, 1)
            refresh = true
        end
    end
end

--[[
#### long press

Copied from cycles (https://monome.org/docs/iii/library/cycles/).
]]

local long_press_metro

local function long_press_key_timer()
    ps("[%d] keylong!", get_time())
    metro.stop(long_press_metro)
    long_press_metro = nil
    held = true
    refresh = true
end

local function handle_long_press(z)
    if z == 1 then
        long_press_metro = metro.new(long_press_key_timer, long_press_ms, 1)
    elseif long_press_metro then
        ps("[%d] keyshort", get_time())
        metro.stop(long_press_metro)
        mode = wrap(mode + 1, 0, 1)
        refresh = true
    else
        ps("[%d] end keylong", get_time())
        held = false
        refresh = true
    end
end

--[[
#### common
]]


function arc_key(z)
    -- uncomment one of the functions below.

    -- handle_single_click(z)
    handle_double_click(z)
    -- handle_long_press(z)
end

local function redraw()
    if refresh then
        local level = mode * 4 + meta * 6
        if held then
            level = 15
        end
        for ring = 1, 4 do
            arc_led_all(ring, level)
        end
        arc_refresh()
        refresh = false
    end
end

local function setup()
    refresh = true
end

setup()

metro.new(redraw, refresh_rate_ms)
