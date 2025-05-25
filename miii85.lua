-- miii85
-- 
-- a step sequencer for the grid zero, inspired by the ryk modular m185 and the intellijel metropolix.
-- 
-- grid layout:
--   - row 1: page selection (pitch, stage count, stage gate mode).
--            maybe also pattern selection after implementing that?
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
midi_clock_in = false

-- change these for different notes:
map = {66,68,70,72,74,76,78,80,82,84,86,88,90,92,94,96}

SEQUENCE_LENGTH = 8
MAX_Y_VALUE = 8

MIDI_CH = 1
MIDI_VEL = 120
page = 1
step = 1
step_count = 1
step_gate_mode = 1
last = 0
ticks = 0

function newPage()
	-- doing this so each page will have independent values arrays.
	local values = {}
	for i = 1, SEQUENCE_LENGTH do
		values[i] = 1
	end

	local grid = function(x, y, z)
		-- button released; ignore.
		if z == 0 then return end
		-- discard out-of-range button presses.
		if y <= MAX_Y_VALUE then return end
		-- bottom row = 1; count up from there.
		values[x] = 17 - y
	end

	local redraw = function()
		-- highlight available interactive area.
		for x = 1, SEQUENCE_LENGTH do
			for y = 17 - MAX_Y_VALUE, 16 do
				grid_led(x, y, 2)
			end
		end

		-- draw active values for each step.
		-- todo: consider tweaking this to show whole row. may also want different
		-- visualizations for different pages, e.g. pulse whole row for note,
		-- count up for stage_count, something else for stage_gate_mode.
		for x = 1, SEQUENCE_LENGTH do
			-- bottom row = 1; count up from there
			grid_led(x, 17 - values[x], step==x and 15 or 5)
		end
	end

	return {
		values = values,
		grid = grid,
		redraw = redraw
	}
end

page_note = newPage()
page_stage_count = newPage()
page_stage_gate_mode = newPage()
pages = {page_note, page_stage_count, page_stage_gate_mode}

tick = function()
	-- todo: don't turn off last note if in gate mode 8
	-- TODO: send note off to correct channel after changing channels
	if last > 0 then midi_note_off(map[last], nil, MIDI_CH) end
	-- stay on current step for number of counts specified in stage_counts.
	if step_count < page_stage_count.values[step] then
		step_count = step_count + 1
	else
		step = (step % SEQUENCE_LENGTH) + 1
		step_count = 1
	end

	-- use gate mode to determine whether next note should play.
	next_note = page_note.values[step]
	step_gate_mode = page_stage_gate_mode.values[step]
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

	if next_note > 0 then midi_note_on(map[next_note], nil, MIDI_CH) end
	last = next_note

	redraw()
end

grid = function(x, y, z)
	-- button released; ignore.
	if z==0 then return end
	if y==1 then
		-- top row; switch pages if in range.
		if pages[x] ~= nil then page  = x end
	elseif y==2 then
		-- second row; set midi channel
		MIDI_CH = x
	else
		if pages[page] ~= nil then pages[page].grid(x, y, z) end
	end

	redraw()
end

redraw = function()
	grid_led_all(0)
	-- top row: draw active page.
	grid_led(page, 1, 5)
	-- second row: draw midi channel.
	grid_led(MIDI_CH, 2, 5)
	-- trigger redraw logic for active page.
	if pages[page] ~= nil then pages[page].redraw() end
	grid_refresh()
end

midi_rx = function(d1,d2,d3,d4)
	if d1==8 and d2==240 then
		ticks = ((ticks + 1) % 12)
		if ticks == 0 and midi_clock_in then tick() end
	else
		ps("midi_rx %d %d %d %d",d1,d2,d3,d4)
	end
end


-- begin

if not midi_clock_in then
	-- 150ms per step
	metro.new(tick, 150)
end

redraw()
