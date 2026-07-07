--[[
stack

a sequencer inspired by tinge, by daedelus x rainbow circuit.
https://www.rainbowcircuit.co/devices/tinge

initial thoughts:

three arcs should be individual segments.
one arc shoul be the combination.

knob for individual segments will control speed.
knob for combination could control... number of note trigger points maybe?
]]

local refresh_rate = 0.012 -- 12 ms

-- ## ring ##
--
-- high level: need to know how fast this segment is spinning, and what the activation points/boundaries are.
--
-- need to know:
-- - which ring (1-4)
-- - what it's rotational position is.
--   (might be nice to have a `spin` or `rotate` method exposed...)
--   (i.e. like `spin(0.02)` to advance 0.02 segments.
--   (if we do this, then something else has to be responsible for advancing ring position)
--   (well, it's either this, or we expose an `on_tick` function and define speed for them, which feels weird...)
--   (i think it would be better for the script to have a `tick` function that advanced the position of the rings.
-- - what the start point is
-- - what the end point is
--   (would it make more sense to expect callers to fetch value for point every time?)
--   (sounds bad...)
--   (maybe a `on_value_change` callback? then each trigger can subscribe to get changes for the point they care about.)
--   (yeah, "do something when the value at this point changes" seems reasonable to me.
--
-- data model
-- - ring (or n): the active ring number
-- - segment_enabled: 64-item array.
-- - speed: float
-- - offset: integer
-- - (some sort of callback?)
--   (i guess this might enforce a single activation point...)
--   (unless we make the callback accept a section (LED number) as an input...)
--   (something like an on_enable or on_disable?) (that feels pretty limited in scope...)
--   (do we want to register change, or discrete values at different places?)
--   (if we need to detect overlaps, then, for a given position, we need to know the value of each ring for that position)
--   (so, i guess we could also just have a value getter for a particular position...)
-- - set_val(n, d)
--   (this feels kind of like arc_led...)

-- ## trigger ##
-- (name tbd. potential alternatives: threshold. activation point (a bit wordy) boundary.)
--
-- high level: on a tick, we want to be able to have a trigger check the values of the three rings.
--
-- need to know:
-- - what is the current value?
-- - what was the value on the last tick? or, has the value changed since the last tick?
-- - is it currently note-on?
-- - was it note-on last tick? or, has the note-on status changed since the last tick?
--   (would it make since to have some sort of `on_note_change` callback?)
--
-- data model
-- - position: integer, 1-64 (matches number of LEDs in a ring)
-- - on_value: callback, gets called on every tick?
--   (idea: pass function that calls for every LED on every tick... actually that sounds bad...)

-- IDEA
-- 1. spin all three of the rings.
-- 2. update the state of the combo ring (i.e. add up values across the other three rings).
-- 3. update the state at each note based on the state of the combo ring.
-- 4. if the value has changed, send a new note (also need to end the old one).

local should_redraw = false

---Log formatted string with timestamp.
---@param formatted_string string
---@param ... any
local function log(formatted_string, ...)
	local s = "[%f] " .. formatted_string
	ps(s, get_time(), ...)
end

---@class RingSegmentController
---@field ring integer Ring number associated with the controller
---@field speed number Rate of rotation
---@field size integer Number of LED segments considered "active"
---@field start number Where the "active" segment start point is currently
local RingSegmentController = {}
RingSegmentController.__index = RingSegmentController

-- Constructor function
---@param ring integer
---@param speed number
---@return RingSegmentController
function RingSegmentController.new(ring, speed)
	local self = setmetatable({}, RingSegmentController)
	self.ring = ring
	self.speed = speed
	self.size = 32 -- TODO: consider making size configurable.
	self.start = 1
	return self
end

-- Event handler for the event_arc callback, simply pass the values from that
-- function, and controller will decide what to do.
---@param ring integer
---@param delta integer
function RingSegmentController:handle_event_arc(ring, delta)
	if ring ~= self.ring then
		-- ignore
		return
	end

	self.speed = clamp(self.speed + delta / 200, -3, 3)
end

-- Advance the playhead position by internally defined speed.
function RingSegmentController:advance()
	self.start = wrap(self.start + self.speed, 1, 64)

	-- TODO: maybe move this, or tweak this logic...
	should_redraw = true
end

-- Get the LED value at segment i.
---@param i integer
---@return integer led_value
function RingSegmentController:get_led(i)
	local i_offset = math.floor(wrap(i - self.start, 1, 64))
	return i_offset < self.size and 15 or 0
end

-- Get all LED values.
---@return table leds
function RingSegmentController:get_leds()
	-- TODO: is there a better way to do this?
	-- i think that creating all of these temporary tables is causing the script to crash...
	-- https://llllllll.co/t/iii-scripting/74312/18?u=evnander
	local offset_leds = {}

	for i = 1, 64 do
		self:get_led(i)
	end

	return offset_leds
end

-- Initialize ring controls.
local r1 = RingSegmentController.new(1, 1)
local r2 = RingSegmentController.new(2, 0.6)
local r3 = RingSegmentController.new(3, 0.2)

-- Initialize arc event handler.
function event_arc(ring, delta)
	r1:handle_event_arc(ring, delta)
	r2:handle_event_arc(ring, delta)
	r3:handle_event_arc(ring, delta)
end

local function redraw()
	-- only redraw if we have something new to draw
	if not should_redraw then
		return
	end

	should_redraw = false

	for i = 1, 64 do
		local r1_led = r1:get_led(i)
		local r2_led = r2:get_led(i)
		local r3_led = r3:get_led(i)

		-- draw rings 1-3
		arc_led(1, i, r1_led)
		arc_led(2, i, r2_led)
		arc_led(3, i, r3_led)

		-- combine rings 1-3 to determine ring 4
		local combined = 0
		combined = combined + (r1_led > 0 and 2 or 0)
		combined = combined + (r2_led > 0 and 2 or 0)
		combined = combined + (r3_led > 0 and 2 or 0)
		arc_led(4, i, combined)
	end

	-- draw note markers
	--
	-- TODO: actually implement these; just placing them for now to see how
	-- things look.
	--
	-- TODO: maybe make them blink when a midi note gets sent?
	arc_led(4, 1, 15)

	arc_refresh()
end

local function tick()
	r1:advance()
	r2:advance()
	r3:advance()

	-- TODO: decouple redraw and advance?
	redraw()
end

local function setup()
	-- reset arc sensitivity
	for ring = 1, 4 do
		arc_res(ring, 1)
	end

	-- zero out arc LEDs
	arc_led_all(0)

	-- trigger initial draw
	should_redraw = true
end

setup()

local m = metro.init(tick, refresh_rate)
m:start()
