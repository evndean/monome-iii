-- miii85
-- 
-- a step sequencer for the grid zero, inspired by the ryk modular m185 and the intellijel metropolix.
-- 
-- grid layout:
--   - row 1: 1-3 page selection (pitch, stage count, stage gate mode).
--            16 midi clock in on/off.
--            (maybe also pattern selection after implementing that?)
--   - row 2: midi channel selection.
--   - rows 3-8: ?????
--   - rows 9-16: pitch, stage count, stage gate mode.
-- 
-- todo/idea:
--   - custom stage gate mode?
--   - adjustable pattern length (start/end).
--   - skip individual steps.
--   - multiple sequences.
--   - sequence chaining.
--   - adjust notes, tuning on device.

print("miii85 start")

-- change this to toggle clock input:
local midi_clock_in = false
local midi_ch = 1
local MIDI_VEL = 120

-- change these for different notes:
local notes = {66,68,70,72,74,76,78,80,82,84,86,88,90,92,94,96}

local SEQUENCE_LENGTH = 8
local MAX_Y_VALUE = 8


local cur_page = 1
local cur_step = 1
local step_count = 1
local step_gate_mode = 1
local last = 0

---@class Page
---@field values table
---@field event_grid function
---@field redraw function
-- TODO: better way to define these function fields?

---@return Page
local function new_page()
	local page = {
		values = {}
	}

	for i = 1, SEQUENCE_LENGTH do
		page.values[i] = 1
	end

	---@param self Page
	---@param x integer
	---@param y integer
	---@param z integer
	function page.event_grid(self, x, y, z)
		-- button released; ignore.
		if z == 0 then return end
		-- discard out-of-range button presses.
		if y <= MAX_Y_VALUE then return end
		-- bottom row = 1; count up from there.
		self.values[x] = 17 - y
	end

	---@param self Page
	function page.redraw(self)
		-- highlight available interactive area.
		for x = 1, SEQUENCE_LENGTH do
			for y = 17 - MAX_Y_VALUE, 16 do
				grid_led(x, y, 2)
			end
		end

		-- draw active values for each step.
		-- TODO: consider tweaking this to show whole row. may also want different
		-- visualizations for different pages, e.g. pulse whole row for note,
		-- count up for stage_count, something else for stage_gate_mode.
		for x = 1, SEQUENCE_LENGTH do
			-- bottom row = 1; count up from there
			grid_led(x, 17 - self.values[x], cur_step==x and 15 or 5)
		end
	end

	return page
end

local page_note = new_page()
local page_stage_count = new_page()
local page_stage_gate_mode = new_page()
local pages = {page_note, page_stage_count, page_stage_gate_mode}

local function tick()
	-- TODO: don't turn off last note if in gate mode 8
	-- TODO: send note off to correct channel after changing channels
	if last > 0 then midi_note_off(notes[last], MIDI_VEL, midi_ch) end
	-- stay on current step for number of counts specified in stage_counts.
	if step_count < page_stage_count.values[cur_step] then
		step_count = step_count + 1
	else
		cur_step = (cur_step % SEQUENCE_LENGTH) + 1
		step_count = 1
	end

	-- use gate mode to determine whether next note should play.
	local next_note = page_note.values[cur_step]
	step_gate_mode = page_stage_gate_mode.values[cur_step]
	if step_gate_mode==1 then
		-- mode 1: note off; play nothing for whole duration of stage.
		next_note = 0
	elseif step_gate_mode==2 then
		-- mode 2: first clock pulse of stage only.
		if step_count~=1 then next_note = 0 end
	elseif step_gate_mode>=3 and step_gate_mode<=6 then
		-- mode 3: note on every clock pulse.
		-- mode 4: note on every second clock pulse.
		-- mode 5: note on every third clock pulse.
		-- mode 6: note on every fourth clock pulse.
		if (step_count-1) % (step_gate_mode-2) ~= 0 then next_note = 0 end
	elseif step_gate_mode==7 then
		-- mode 7: random.
		if math.random(2)~=1 then next_note = 0 end
	else
		-- mode 8: long.
		-- todo: figure out how to implement this...
	end

	if next_note > 0 then midi_note_on(notes[next_note], MIDI_VEL, midi_ch) end
	last = next_note

	redraw()
end

function event_grid(x, y, z)
	if z==0 then
		-- button released; ignore.
		return
	end

	if y==1 then
		-- top row; switch pages if in range.
		if pages[x] ~= nil then cur_page  = x end
		-- toggle midi clock in.
		if x==16 then midi_clock_in = not midi_clock_in end
	elseif y==2 then
		-- second row; set midi channel
		midi_ch = x
	else
		if pages[cur_page] ~= nil then pages[cur_page]:event_grid(x, y, z) end
	end

	redraw()
end

-- TODO: rewrite for async redraw (function must stay global until then)
function redraw()
	grid_led_all(0)
	-- top row: draw active page.
	for x = 1, #pages do
		grid_led(x, 1, x == cur_page and 10 or 2)
	end
	-- draw midi_clock_in state (on = bright; todo maybe reverse this)
	grid_led(16, 1, midi_clock_in and 10 or 2)
	-- second row: draw midi channel.
	grid_led(midi_ch, 2, 5)
	-- trigger redraw logic for active page.
	if pages[cur_page] ~= nil then pages[cur_page]:redraw() end
	grid_refresh()
end

-- TODO: rewrite this using the updated midi functions
-- midi_rx = function(d1,d2,d3,d4)
-- 	if d1==8 and d2==240 then
-- 		ticks = ((ticks + 1) % 12)
-- 		if ticks == 0 and midi_clock_in then tick() end
-- 	else
-- 		ps("midi_rx %d %d %d %d",d1,d2,d3,d4)
-- 	end
-- end


-- begin

local function maybe_tick()
	if not midi_clock_in then tick() end
end

---@type Metro
local m
if not midi_clock_in then
	-- 150ms per step
	m = metro.init(maybe_tick, 0.15)
	m:start()
end

redraw()
