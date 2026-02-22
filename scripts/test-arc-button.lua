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
local refresh_rate_ms = 12
local refresh = false


function handle_single_click(z)
    ps("z == %d", z)
    if z == 0 then
    elseif z == 1 then
        mode = wrap(mode + 1, 0, 1)
        refresh = true
    end
end

-- i tried defining this inside the function but it didn't seem to work.
local double_click_metro

function handle_double_click_using_metro(z)
    -- IDEA:
    -- on click, create a metro.
    -- on tick 1, do nothing.
    -- on tick 2, toggle mode if a second click hasn't arrived.
    -- if the second click does arrive, stop the metro, and toggle meta.
    --
    -- this seems to work, but we eventually run out of metros, even though setting a global variable to `nil` is supposed to remove it.

    if z == 1 then
        if double_click_metro == nil then
            print("m is nil")
            double_click_metro = metro.new(
                function(stage)
                    if stage == 1 then
                        -- do nothing on first tick
                        print("arc_key: metro: first tick, doing nothing")
                    elseif stage == 2 then
                        print("arc_key: metro: second tick, advancing mode")
                        mode = wrap(mode + 1, 0, 1)
                        double_click_metro = nil
                        refresh = true
                    end
                end,
                double_click_ms,
                2
            )
        else
            print("arc_key: double-click")
            metro.stop(double_click_metro)
            double_click_metro = nil
            meta = wrap(meta + 1, 0, 1)
            refresh = true
        end
    end
end

-- i tried defining these handle_double_click_using_ts but i think it just kept re-initializing them each time.

-- arc_key z (for handle_double_click_using_ts)
local dcts_z = 0
-- tracks the last time the key was pressed (for handle_double_click_using_ts)
local dcts_last_down_ts
-- (for handle_double_click_using_ts)
metro.new(
    function(stage)
        ps("[%d] dcts_z == %d", get_time(), dcts_z)

        -- use "ts == nil" to know that we've finished handling the last series of clicks.
        -- single-click: we need to set the ts, then check the delta.
        -- double-click: we've already set the ts, so check the delta.

        if dcts_z == 1 then
            if dcts_last_down_ts == nil then
                ps("[%d] first click received", get_time())
                dcts_last_down_ts = get_time()
            elseif get_time() - dcts_last_down_ts < double_click_ms then
                ps("[%d] second click received", get_time())
                dcts_last_down_ts = nil
            end
        else
            if dcts_last_down_ts == nil then
                ps("[%d] nothing to do", get_time())
            elseif get_time() - dcts_last_down_ts < double_click_ms then
                ps("[%d] waiting for second click", get_time())
            else
                ps("[%d] no second click received; was single click", get_time())
                dcts_last_down_ts = nil
            end
        end
    end,
    refresh_rate_ms
)

function handle_double_click_using_ts(z)
    -- IDEA:
    -- use a timestamp to tell when we first pressed.
    -- we still need a metro to check for timestamp diffs, but this can be a single, long-running metro.
    -- i had to define the metro outside the scope of this function, because it kept getting recreated when
    -- i defined it within the function scope.

    -- one problem with this approach is that any clicks that happen between metro ticks get dropped, so we
    -- need to have some handling for setting those variables here as well.
    if dcts_last_down_ts == nil then
        dcts_last_down_ts = get_time()
    end

    -- hmmm, even if we do that, it's not great.

    dcts_z = z
end

function handle_long_press(z)
    -- ...i guess the problem here is that we still need a metro if we want to be able to know how much
    -- time a button has been held down for (i.e. to differentiate between short and long presses).

    -- TODO try to implement this.
end

function arc_key(z)
    -- uncomment one of the functions below.

    -- handle_single_click(z)
    handle_double_click_using_metro(z)
    -- handle_double_click_using_ts(z)
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
