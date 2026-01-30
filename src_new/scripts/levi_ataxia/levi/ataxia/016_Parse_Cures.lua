--[[mudlet
type: script
name: Parse Cures
hierarchy:
- Levi_Ataxia
- LEVI
- Ataxia
- Ataxia
- Combat
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--


function tarClassCure(getAff)
	local x = (ataxiaNDB_Exists(target) and ataxiaNDB.players[target].class or "None")
	local aff = ""
	local affCures = {
		Alchemist = {"stupidity", "stupid"},
		Blademaster = {"weariness", "weariness"},
		Depthswalker = {"recklessness", "reckless"},
		Druid = {"weariness", "weariness"},
		Infernal = {"weariness", "weariness"},
		Magi = {"haemophilia", "haemophilia"},
		Monk = {"weariness", "weariness"},
		Paladin = {"weariness", "weariness"},
		Psion = {"confusion", "confusion"},
		Runewarden = {"weariness", "weariness"},
		Sentinel = {"weariness", "weariness"},
		Serpent = {"weariness", "weariness"},
		None = {"paralysis", "paralyse"},
	}
	if not table.contains(affCures, x) then x = "None" end
	if getAff then
		aff = affCures[x][2]
	else
		aff = affCures[x][1]
	end
	return aff
end

