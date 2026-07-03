---@meta
-- iii framework type definitions for LuaLS

-- ############
-- DEVICE: GRID
-- ############

---Callback function for grid key events.
---@type fun(x: integer, y: integer, z: integer)
event_grid = nil

---Set coordinates (x, y) to value z, or if rel is true, add z to existing value.
---@param x integer
---@param y integer
---@param z integer 0-15 brightness
---@param rel? boolean
function grid_led(x, y, z, rel) end

---Returns value at coordinates (x, y).
---@param x integer
---@param y integer
---@return integer brightness
function grid_led_get(x, y) end

---Set all values to z, or if rel is true, add z to all existing values.
---@param z integer 0-15 brightness
---@param rel? boolean
function grid_led_all(z, rel) end

---Set global intensity to brightness b, triggers refresh.
---@param b integer
function grid_intensity(b) end

---Refresh LED values.
function grid_refresh() end

---Returns x size.
---@return integer
function grid_size_x() end

---Returns y size.
---@return integer
function grid_size_y() end

-- ###########
-- DEVICE: ARC
-- ###########

---Callback for arc knob ring n delta d.
---@type fun(n: integer, d: integer)
event_arc = nil

---Callback for arc key events.
---@type fun(z: integer)
event_arc_key = nil

---Set knob resolution for ring n to div (default 1, use higher values for less resolution).
---@param n integer 1-4
---@param div integer 1-1024 (higher values = less resolution)
function arc_res(n, div) end

---Set ring n segment x to value z, or if rel is true, add z to existing value.
---@param n integer 1-4
---@param x integer 1-64
---@param z integer 0-15
---@param rel? boolean
function arc_led(n, x, z, rel) end

---Set all values of ring n to value z, or if rel is true, add z to existing values.
---@param n integer 1-4
---@param z integer 0-15
---@param rel? boolean
function arc_led_ring(n, z, rel) end

---Set all values to z, or if rel is true, add z to existing values.
---@param z integer 0-15
---@param rel? boolean
function arc_led_all(z, rel) end

---Refresh LED values.
function arc_refresh() end

-- ####
-- MIDI
-- ####

-- USB MIDI device functions.

---Callback function for incoming USB MIDI.
---@type fun(byte1: integer, byte2: integer, byte3: integer)
event_midi = nil

---Returns decoded midi byte array data as a labeled table.
--- TODO: type for data param.
--- TODO: type for return.
function midi_to_msg(data) end

---Table can be data bytes or msg, sent to USB MIDI port.
--- TODO: type for table param.
--- TODO: type for return.
function midi_out(table) end

---Shortcut function for sending note on.
---@param note integer 0-127
---@param vel integer 0-127
---@param ch integer 1-16
function midi_note_on(note, vel, ch) end

---Shortcut function for sending note off.
---@param note integer 0-127
---@param vel integer 0-127
---@param ch integer 1-16
function midi_note_off(note, vel, ch) end

---Shortcut function for sending cc.
---@param cc integer 0-127
---@param val integer 0-127
---@param ch integer 1-16
function midi_cc(cc, val, ch) end

-- #####
-- METRO
-- #####

-- Repeating timers which execute a callback function.
--
-- Note these are hardware driven, limited to 15 total. You can of course use one
-- fast timer to creatively manage sub-timers if you need more.

---The table exposed by iii for managing metro.
metro = {}

---The table returned by the metro.init function.
---@class Metro
---@field id integer
---@field time number Time in seconds, can be manually adjusted.
Metro = {}

---Initialize a metro m, with callback function, time in seconds, (optional)
---count before stop.
---@param callback function
---@param time_sec number
---@param count_optional? integer
---@return Metro
function metro.init(callback, time_sec, count_optional) end

---Start metro, with optional new time value. can be repeatedly called to restart and set new values.
---@param self Metro
---@param time_optional? number
function Metro.start(self, time_optional) end

---Stop metro.
---@param self Metro
function Metro.stop(self) end

---Free metro.
---@param id integer
function metro.free(id) end

---Free all metros.
function metro.free_all() end

-- ####
-- SLEW
-- ####

-- Stepped interpolation between values over specified time interval. No hard
-- limit to how many slews can be created, though memory or CPU time will
-- eventually cause problems with high numbers of simultaneous slews.

---The table exposed by iii for managing slew.
slew = {}

---Create a new slew with callback function, from start_val to end_val over
---interval time_sec, with callbacks on quantum q (default 1). Returns id which
---is used to further manage the slew.
---@param callback function
---@param start_val number
---@param end_val number
---@param time_sec number
---@param q? number (default 1)
---@return integer id
function slew.new(callback, start_val, end_val, time_sec, q) end

---Interrupt running slew, set new destination from current position, new time
---interval optional.
---@param id integer
---@param end_val number
---@param time_optional? number
function slew.to(id, end_val, time_optional) end

---Freezes slew, can be resumed with slew.to.
---@param id integer
function slew.freeze(id) end

---Freezes all slews.
function slew.allfreeze() end

---Stops and removes a running slew.
---@param id integer
function slew.stop(id) end

---Stop and remove all slews.
function slew.allstop() end

-- ####
-- PSET
-- ####

---Assign name to pset files to be written and read.
---@param name string
function pset_init(name) end

---Write pset number index with data table.
---@param index integer The preset slot index.
---@param data table The table of values to persist.
function pset_write(index, data) end

---Deletes pset at index.
---@param index integer
function pset_delete(index) end

---Read pset number index into table.
---@param index integer The preset slot index.
---@return table data The table of values stored at this index.
function pset_read(index) end

-- #####
-- UTILS
-- #####

---Send text to lua interpreter, execute command.
---@param lua_command string
function dostring(lua_command) end

---Returns time in seconds with usec precision.
---@return number time The time in seconds with usec precision.
function get_time() end

---Print a formatted string, like printf.
---@param formatted_string string
---@param ... any Values to format into the string
function ps(formatted_string, ...) end

---Print table.
---@param table table
function pt(table) end

---Returns n clamped between min and max.
---@param n number The input value
---@param min number The lower bound
---@param max number The upper bound
---@return number
function clamp(n, min, max) end

---Returns n rounded to nearest quant (default 1).
---@param n number
---@param quant? number (default 1)
---@return number
function round(n, quant) end

---Returns n transposed from range (slo, shi) to range (dlo, dhi).
---@param n number The value to be transposed
---@param slo number Source range low
---@param shi number Source range high
---@param dlo number Destination range low
---@param dhi number Destination range high
---@return number
function linlin(n, slo, shi, dlo, dhi) end

---Returns n wrapped within range (min, max).
---@param n number
---@param min number
---@param max number
---@return number
function wrap(n, min, max) end
