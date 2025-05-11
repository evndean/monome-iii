-- miii85
-- 
-- a step sequencer for the grid zero, inspired by the ryk modular m185 and the intellijel metropolix.
-- 
-- grid layout:
--   - row 1: playhead position.
--   - row 2: page selection (pitch, stage count, stage gate mode).
--            maybe also pattern selection after implementing that?
--   - rows 3-8: ?????
--   - rows 9-16: pitch, stage count, stage gate mode.
-- 
-- todo/idea:
--   - stage gate mode.
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

ch = 0
page = 1
step = 1
last = 0
note = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
stage_count = {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1}
ticks = 0

tick = function()
	if last > 0 then midi_note_off(map[last]) end
	-- todo: use stage_count to decide whether to move to next step.
	step = (step % 16) + 1
	last = note[step]
	if last > 0 then midi_note_on(map[last]) end
	redraw()
end

grid = function(x, y, z)
	-- button released; ignore.
	if z==0 then return end
	if y==1 then
		-- top row; ignore button presses.
	elseif y==2 then
		-- second row; switch pages if in range.
		if x<=2 then
			page=x
		end
	else
		if page==1 then
			handle_pitch(x, y, x)
		elseif page==2 then
			handle_stage_count(x, y, x)
		end
	end
	redraw()
end

handle_pitch = function(x, y, z)
	if note[x] == y then note[x] = 0
	else note[x] = y end
end

handle_stage_count = function(x, y, z)
	-- button released; ignore.
	if z==0 then return end
	-- discard out-of-range button presses.
	if y<=8 then return end
	-- bottom row = 1, count up from there.
	stage_count[x] = 17 - y
end

redraw = function()
	grid_led_all(0)
	-- draw clock position.
	grid_led(step, 1, 5)
	-- draw active page.
	grid_led(page, 2, 5)
	if page==1 then
		redraw_pitch()
	elseif page==2 then
		redraw_stage_count()
	end
	grid_refresh()
end

redraw_pitch = function()
	for n=1,16 do
		if note[n] > 0 then
			grid_led(n, note[n], step==n and 15 or 5)
		end
	end
end

redraw_stage_count = function()
	-- todo: consider tweaking this to show whole row
	for n=1,16 do
		if stage_count[n] > 0 then
			grid_led(n, 17 - stage_count[n], step==n and 15 or 5)
		end
	end
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
