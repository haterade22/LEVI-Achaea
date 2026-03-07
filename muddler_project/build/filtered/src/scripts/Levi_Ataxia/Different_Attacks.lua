-- Text highlighting for incoming limb attacks.
-- Actual damage tracking is handled by the regex trigger in 002_Track_The_Damage.lua.

local function highlightLimb(text)
	selectString(text, 1)
	setBold(true)
	fg("a_blue")
	resetFormat()
	deselect()
end

--> Blademaster
function armslash_selfLimbhit(side)
	highlightLimb(side)
end

function legslash_selfLimbhit(side)
	highlightLimb(side)
end

function centreslash_selfLimbhit(section)
	highlightLimb(section)
end

--> Earth Lord
function earthLord_selfLimbHit(limb)
	highlightLimb(limb)
end

--> Knight
function snb_selfLimbHit(limb)
	highlightLimb(limb)
end

function dwc_selfLimbHit(limb)
	highlightLimb(limb)
end

--> Priest
function priest_selfLimbHit(limb)
	highlightLimb(limb)
end

--> Dragon/Druid
function quarterHit_selfLimbHit(limb)
	highlightLimb(limb)
end

--> Magi
function staffStrike_selfLimbHit(element, limb)
	highlightLimb(limb)
end

--> Sylvan
function thornrend_selfLimbHit(limb)
	highlightLimb(limb)
end
