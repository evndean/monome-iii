---@meta
-- iii framework type definitions for LuaLS

-- ####
-- GRID
-- ####

--- Callback for grid key events.
---@type fun(x: integer, y: integer, z: integer)
grid = nil

---@param z integer 0-15 brightness
function grid_led_all(z) end

---@param x integer
---@param y integer
---@param z integer 0-15 brightness
function grid_led(x, y, z) end

---@param x integer
---@param y integer
---@param z integer
---@param zmin integer
---@param zmax integer
function grid_led_rel(x, y, z, zmin, zmax) end

---@param x integer
---@param y integer
---@return integer brightness
function grid_led_get(x, y) end

function grid_refresh() end

---@return integer
function grid_size_x() end

---@return integer
function grid_size_y() end

-- ###
-- ARC
-- ###

--- Callback for arc turn events.
---@type fun(ring: integer, delta: integer)
arc = nil

--- Callback for arc key events.
---@type fun(z: integer)
arc_key = nil

--- Sets knob tick division (sensitivity).
---@param ring integer 1-4
---@param div integer 1-1024 (1 = max resolution)
function arc_res(ring, div) end

-- Sets level for a specific LED.
---@param ring integer 1-4
---@param led integer 1-64
---@param level integer 0-15
function arc_led(ring, led, level) end

--- Adds level to the current LED value.
---@param ring integer 1-4
---@param led integer 1-64
---@param level integer Amount to add (can be negative)
---@param level_min? integer Optional lower bound (default 0)
---@param level_max? integer Optional upper bound (default 15)
function arc_led_rel(ring, led, level, level_min, level_max) end

-- Sets all LEDs to level.
---@param ring integer
---@param level integer 0-15
function arc_led_all(ring, level) end

function arc_refresh() end

-- ####
-- MIDI
-- ####

--- Callback for incoming MIDI messages.
---@type fun(ch: integer, status: integer, data1: integer, data2: integer)
midi_rx = nil

--- Sends a MIDI Note On message.
---@param note integer 0-127
---@param vel integer 0-127
---@param ch integer 1-16
function midi_note_on(note, vel, ch) end

--- Sends a MIDI Note Off message.
---@param note integer 0-127
---@param vel integer 0-127
---@param ch integer 1-16
function midi_note_off(note, vel, ch) end

--- Sends a MIDI Control Change message.
---@param cc integer 0-127
---@param val integer 0-127
---@param ch integer 1-16
function midi_cc(cc, val, ch) end

--- Sends a raw MIDI message.
---@param ch integer 1-16
---@param status integer Status byte
---@param data1 integer Data byte 1
---@param data2 integer Data byte 2
function midi_tx(ch, status, data1, data2) end

-- #####
-- METRO
-- #####

metro = {}

---@param callback function
---@param time_ms number
---@param count_optional? integer
---@return integer id
function metro.new(callback, time_ms, count_optional) end

---@param id integer
function metro.stop(id) end

-- ####
-- SLEW
-- ####

slew = {}

---@param callback function
---@param start_val number
---@param end_val number
---@param time_ms number
---@param quant? number
---@return integer id
function slew.new(callback, start_val, end_val, time_ms, quant) end

--- Stops a running slew.
---@param id integer The ID returned by slew.new
function slew.stop(id) end

-- ####
-- PSET
-- ####

--- Reads a preset table from the given index.
---@param index integer The preset slot index.
---@return table data The table of values stored at this index.
function pset_read(index) end

--- Writes a table of data to a specific preset index.
---@param index integer The preset slot index.
---@param data table The table of values to persist.
function pset_write(index, data) end

-- #####
-- UTILS
-- #####

--- Executes a string as Lua code.
---@param str string
function dostring(str) end

--- Returns the time since boot in milliseconds.
---@return number
function get_time() end

--- Prints a formatted string (Print String).
---@param formatted_string string
---@param ... any Values to format into the string
function ps(formatted_string, ...) end

--- Prints a table's contents to the console (Print Table).
---@param table_to_print table
function pt(table_to_print) end

--- Clamps a value between a minimum and maximum.
---@param n number The input value
---@param min number The lower bound
---@param max number The upper bound
---@return number
function clamp(n, min, max) end

--- Rounds a number to the nearest quantum.
---@param number number
---@param quant number The step to round to (e.g., 1.0 or 0.25)
---@return number
function round(number, quant) end

--- Maps a value from one linear range to another.
---@param slo number Source range low
---@param shi number Source range high
---@param dlo number Destination range low
---@param dhi number Destination range high
---@param f number The value to map
---@return number
function linlin(slo, shi, dlo, dhi, f) end

--- Wraps a value within a range (integer or float).
---@param n number
---@param min number
---@param max number
---@return number
function wrap(n, min, max) end