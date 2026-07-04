local key_on = {}

local function setup()
    -- initialize all key states to "off"
    for x = 1, 16 do
        local row = {}
        for y = 1, 16 do
            row[y] = 0
        end
        key_on[x] = row
    end

    -- turn off all LEDs
    grid_led_all(0)
    grid_refresh()
end

function event_grid(x, y, z)
    ps("grid %d %d %d", x, y, z)

    -- max brightness on key down, switch between dim and off on key up
    ---@type integer
    local new_level
    if z == 1 then
        new_level = 15
    else
        local new_key_on = wrap(key_on[x][y] + 1, 0, 1)
        new_level = new_key_on == 1 and 5 or 0
        key_on[x][y] = new_key_on
    end

    grid_led(x, y, new_level)
    grid_refresh()
end

setup()
