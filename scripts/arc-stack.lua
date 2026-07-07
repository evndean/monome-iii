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

-- Returns whether the controller is currently active at point x.
---@param x integer
---@return boolean
function RingSegmentController:get_active_at(x)
	local i_offset = math.floor(wrap(x - self.start, 1, 64))
	return i_offset < self.size
end

function RingSegmentController:redraw()
	for i = 1, 64 do
		local intensity = self:get_active_at(i) and 15 or 0
		arc_led(self.ring, i, intensity)
	end
end

-- A single note activation point.
---@class Trigger
---@field position integer Point on the ring associated with the trigger.
local Trigger = {}
Trigger.__index = Trigger

-- Contructor function.
---@param position integer
---@return Trigger
function Trigger.new(position)
	local self = setmetatable({}, Trigger)
	self.position = position
	return self
end

-- IDEA: handle tick
--
-- ---
-- for rings 1, 3:
--     check values emitted in last rotation
--     if there was a change:
--         we will want to send a new midi note
-- if we want to send a new midi note:
--     calculate the new midi note value
--     send midi off for old note
--     send midi on for new note
-- ---
--
-- so, we need:
-- - store the previous values
-- - store the previous midi note
-- - access to the values emitted on the last tick by each ring

function Trigger:redraw()
	-- TODO: maybe blink on note send?
	arc_led(4, self.position, 15)
end

-- Initialize ring controls.
local r1 = RingSegmentController.new(1, 1)
local r2 = RingSegmentController.new(2, 0.6)
local r3 = RingSegmentController.new(3, 0.2)

-- Initialize notes.
-- TODO: eventually want to make this runtime-configurable using arc encoder.
local n1 = Trigger.new(1)

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

	-- redraw segment rings
	r1:redraw()
	r2:redraw()
	r3:redraw()

	-- redraw combined, trigger ring
	for i = 1, 64 do
		local r1_intensity = r1:get_active_at(i) and 2 or 0
		local r2_intensity = r2:get_active_at(i) and 2 or 0
		local r3_intensity = r3:get_active_at(i) and 2 or 0
		local combined = r1_intensity + r2_intensity + r3_intensity
		arc_led(4, i, combined)
	end

	-- draw note markers
	n1:redraw()

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
