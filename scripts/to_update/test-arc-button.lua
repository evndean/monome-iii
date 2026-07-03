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
local dc_metro

local function dc_key_timer()
    ps("[%d] single click", get_time())
    metro.stop(dc_metro)
    dc_metro = nil

    mode = wrap(mode + 1, 0, 1)
    refresh = true
end

local function handle_double_click(z)
    if z == 1 then
        if dc_metro == nil then
            dc_metro = metro.new(dc_key_timer, double_click_ms, 1)
        else
            ps("[%d] double click", get_time())
            metro.stop(dc_metro)
            dc_metro = nil
            meta = wrap(meta + 1, 0, 1)
            refresh = true
        end
    end
end

--[[
#### long press

Copied from cycles (https://monome.org/docs/iii/library/cycles/).
]]

local lp_metro

local function lp_key_timer()
    ps("[%d] keylong!", get_time())
    metro.stop(lp_metro)
    lp_metro = nil
    held = true
    refresh = true
end

local function handle_long_press(z)
    if z == 1 then
        lp_metro = metro.new(lp_key_timer, long_press_ms, 1)
    elseif lp_metro then
        ps("[%d] keyshort", get_time())
        metro.stop(lp_metro)
        mode = wrap(mode + 1, 0, 1)
        refresh = true
    else
        ps("[%d] end keylong", get_time())
        held = false
        refresh = true
    end
end

--[[
#### all

Handle both long press and double click.

I tried writing the "stop" functions as a single function with a passed "m" paramter,
but lua passes arguments of number type by value, so the "reassign to nil" logic didn't work.
]]

local a_dc_metro
local a_lp_metro

local function stop_dc_metro()
    if a_dc_metro then
        metro.stop(a_dc_metro)
        a_dc_metro = nil
    end
end

local function stop_lp_metro()
    if a_lp_metro then
        metro.stop(a_lp_metro)
        a_lp_metro = nil
    end
end

local function a_dc_key_timer()
    if held then
        return
    end

    ps("[%d] single click", get_time())
    stop_dc_metro()
    stop_lp_metro()

    mode = wrap(mode + 1, 0, 1)
    refresh = true
end

local function a_lp_key_timer()
    ps("[%d] keylong!", get_time())
    stop_dc_metro()
    stop_lp_metro()

    held = true
    refresh = true
end

local function handle_all(z)
    if z == 1 then
        if a_lp_metro == nil then
            a_lp_metro = metro.new(a_lp_key_timer, long_press_ms, 1)
        end

        if a_dc_metro == nil then
            a_dc_metro = metro.new(a_dc_key_timer, long_press_ms + 1, 1)
        else
            ps("[%d] double click", get_time())
            stop_dc_metro()
            stop_lp_metro()

            meta = wrap(meta + 1, 0, 1)
            refresh = true
        end
    else
        if held then
            ps("[%d] end keylong", get_time())
            stop_dc_metro()
            stop_lp_metro()

            held = false
            refresh = true
        elseif a_dc_metro then
            ps("[%d] maybe double click", get_time())
            stop_lp_metro()
        end
    end
end

--[[
#### common
]]


function arc_key(z)
    -- uncomment one of the functions below.

    -- handle_single_click(z)
    -- handle_double_click(z)
    -- handle_long_press(z)
    handle_all(z)
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
