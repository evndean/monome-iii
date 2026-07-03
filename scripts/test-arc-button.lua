--[[
basic script to test some button functionality.

- single-click should toggle between states.
- double-click should toggle between meta states.
- long press should be its own state, return to previous state when done.
]]

local meta = 0
local mode = 0
local held = false
local double_click_s = 0.2
local long_press_s = 0.5
local refresh_rate = 0.012 -- 12 ms
local refresh = false

-- Log with a timestamp.
local function log(s)
    ps("[%f] %s", get_time(), s)
end

-- Stop and remove a metro.
-- Returns a nil value so the source metro can be cleared out as well.
---@param m Metro|nil
---@return nil
local function rm_metro(m)
    if m then
        m:stop()
        metro.free(m.id)
        -- note: this only removes the reference within this function.
        -- callers will still need to reassign to nil, which is why we this
        -- function returns nil.
        m = nil
    end
    return nil
end

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
---@type Metro|nil
local dc_metro

local function dc_key_timer()
    log("single click")
    dc_metro = rm_metro(dc_metro)
    mode = wrap(mode + 1, 0, 1)
    refresh = true
end

local function handle_double_click(z)
    if z == 1 then
        if dc_metro == nil then
            dc_metro = metro.init(dc_key_timer, double_click_s, 1)
            dc_metro:start()
        else
            log("double click")
            dc_metro = rm_metro(dc_metro)
            meta = wrap(meta + 1, 0, 1)
            refresh = true
        end
    end
end

--[[
#### long press

Copied from cycles (https://monome.org/docs/iii/library/cycles/).
]]

---@type Metro|nil
local lp_metro

local function lp_key_timer()
    log("keylong")
    lp_metro = rm_metro(lp_metro)
    held = true
    refresh = true
end

local function handle_long_press(z)
    if z == 1 then
        lp_metro = metro.init(lp_key_timer, long_press_s, 1)
        lp_metro:start()
    elseif lp_metro then
        log("keyshort")
        lp_metro = rm_metro(lp_metro)
        mode = wrap(mode + 1, 0, 1)
        refresh = true
    else
        log("end keylong")
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

---@type Metro|nil
local a_dc_metro

---@type Metro|nil
local a_lp_metro

local function stop_dc_metro()
    a_dc_metro = rm_metro(a_dc_metro)
end

local function stop_lp_metro()
    a_lp_metro = rm_metro(a_lp_metro)
end

local function a_dc_key_timer()
    if held then
        return
    end

    log("single click")
    stop_dc_metro()
    stop_lp_metro()

    mode = wrap(mode + 1, 0, 1)
    refresh = true
end

local function a_lp_key_timer()
    log("keylong")
    stop_dc_metro()
    stop_lp_metro()

    held = true
    refresh = true
end

local function handle_all(z)
    if z == 1 then
        if a_lp_metro == nil then
            a_lp_metro = metro.init(a_lp_key_timer, long_press_s, 1)
            a_lp_metro:start()
        end

        if a_dc_metro == nil then
            a_dc_metro = metro.init(a_dc_key_timer, long_press_s + 0.001, 1)
            a_dc_metro:start()
        else
            log("double click")
            stop_dc_metro()
            stop_lp_metro()

            meta = wrap(meta + 1, 0, 1)
            refresh = true
        end
    else
        if held then
            log("end keylong")
            stop_dc_metro()
            stop_lp_metro()

            held = false
            refresh = true
        elseif a_dc_metro then
            log("maybe double click")
            stop_lp_metro()
        end
    end
end

--[[
#### common
]]

function event_arc_key(z)
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
            arc_led_ring(ring, level)
        end
        arc_refresh()
        refresh = false
    end
end

local function setup()
    -- reset arc resolution
    for ring = 1, 4 do
        arc_res(ring, 1)
    end

    -- reset LED levels
    arc_led_all(0)
    arc_refresh()

    refresh = true
end

setup()

local m = metro.init(redraw, refresh_rate)
m:start()
