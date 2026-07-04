--[[
stack

a sequencer inspired by tinge, by daedelus x rainbow circuit.
https://www.rainbowcircuit.co/devices/tinge

initial thoughts:

three arcs should be individual segments.
one arc shoul be the combination.
not sure whether that should be the first or the last tho.

knob for individual segments will control speed.
knob for combination could control... number of note trigger points maybe?
]]
--

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
