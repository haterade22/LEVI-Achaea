-- Affliction tracking module
-- Tracks afflictions via GMCP events

ataxia.afflictions = ataxia.afflictions or {}

-- Affliction categories for display/priority
ataxia.afflictionCategories = {
	mental = {
		"stupidity", "confusion", "dementia", "paranoia", "hallucinations",
		"hypersomnia", "impatience", "loneliness", "vertigo", "dizziness",
		"indifference", "berserking", "masochism", "recklessness", "weariness"
	},
	physical = {
		"paralysis", "asthma", "slickness", "clumsiness", "sensitivity",
		"blindness", "deafness", "anorexia", "haemophilia", "healthleech"
	},
	limbs = {
		"crippled_left_leg", "crippled_right_leg", "crippled_left_arm", "crippled_right_arm",
		"broken_left_leg", "broken_right_leg", "broken_left_arm", "broken_right_arm",
		"mangled_left_leg", "mangled_right_leg", "mangled_left_arm", "mangled_right_arm"
	},
	writhe = {
		"transfixation", "impaled", "webbed", "roped", "bound", "entangled"
	}
}

-- Add an affliction
function ataxia.addAffliction(aff)
	if not ataxia.afflictions[aff] then
		ataxia.afflictions[aff] = true
		ataxia.events.raise("aff gained", aff)
	end
end

-- Remove an affliction
function ataxia.removeAffliction(aff)
	if ataxia.afflictions[aff] then
		ataxia.afflictions[aff] = nil
		ataxia.events.raise("aff lost", aff)
	end
end

-- Check if we have an affliction
function ataxia.hasAffliction(aff)
	return ataxia.afflictions[aff] == true
end

-- Clear all afflictions (e.g., on death)
function ataxia.clearAfflictions()
	ataxia.afflictions = {}
	ataxia.events.raise("affs cleared")
end

-- Get affliction count
function ataxia.getAfflictionCount()
	return ataxia.tableCount(ataxia.afflictions)
end

-- GMCP handlers
local function onAfflictionAdd()
	local aff = gmcp.Char.Afflictions.Add
	if type(aff) == "table" then
		ataxia.addAffliction(aff.name)
	end
end

local function onAfflictionRemove()
	local aff = gmcp.Char.Afflictions.Remove
	if type(aff) == "table" then
		for _, name in ipairs(aff) do
			ataxia.removeAffliction(name)
		end
	elseif type(aff) == "string" then
		ataxia.removeAffliction(aff)
	end
end

local function onAfflictionList()
	local affs = gmcp.Char.Afflictions.List
	if type(affs) == "table" then
		ataxia.afflictions = {}
		for _, aff in ipairs(affs) do
			if type(aff) == "table" and aff.name then
				ataxia.afflictions[aff.name] = true
			end
		end
	end
end

-- Register GMCP handlers
ataxia.events.register("gmcp.Char.Afflictions.Add", onAfflictionAdd, "afflictions_add")
ataxia.events.register("gmcp.Char.Afflictions.Remove", onAfflictionRemove, "afflictions_remove")
ataxia.events.register("gmcp.Char.Afflictions.List", onAfflictionList, "afflictions_list")
