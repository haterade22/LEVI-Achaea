--[[mudlet
type: trigger
name: Rebounding Strip
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Remove Afflictions
attributes:
  isActive: 'yes'
  isFolder: 'no'
  isTempTrigger: 'no'
  isMultiline: 'no'
  isPerlSlashGOption: 'no'
  isColorizerTrigger: 'no'
  isFilterTrigger: 'no'
  isSoundTrigger: 'no'
  isColorTrigger: 'no'
  isColorTriggerFg: 'no'
  isColorTriggerBg: 'no'
triggerType: 0
conditonLineDelta: 0
mStayOpen: 0
mCommand: ''
packageName: ''
mFgColor: '#ff0000'
mBgColor: '#ffff00'
mSoundFile: ''
colorTriggerFgColor: '#000000'
colorTriggerBgColor: '#000000'
patterns:
- pattern: ^You call upon Whiirh to empower your staff and strike (\w+), the power of air dispersing \w+ aura of rebounding.$
  type: 1
- pattern: ^(\w+)'s aura of weapons rebounding disappears.$
  type: 1
- pattern: ^A gust of wind strikes (\w+), throwing (\w+) to the ground.$
  type: 1
- pattern: ^You raze (\w+)'s aura of rebounding with .+\.$
  type: 1
- pattern: ^You whip .+ through the air in front of (\w+), to no effect.$
  type: 1
- pattern: ^You try to flay a non-existent aura of rebounding from (\w+).$
  type: 1
- pattern: ^You flay away (\w+)'s aura of rebounding defence\.$
  type: 1
- pattern: ^Your mace ignites in holy flame, burning away (\w+)'s protective aura.$
  type: 1
- pattern: ^You deliver a single, powerful blow against the aura of rebounding surrounding (\w+), fracturing it.$
  type: 1
- pattern: ^You lurch forward at (\w+), swinging .+ in a wildly innacurate blow.$
  type: 1
- pattern: ^\w+ razes (\w+)'s aura of rebounding with a .+.$
  type: 1
- pattern: ^\w+ razes (\w+)'s aura of rebounding with an .+.$
  type: 1
- pattern: ^\w+ razes (\w+)'s aura of rebounding with .+.$
  type: 1
- pattern: ^Planting your feet, you whirl a .+ over your head before bringing it down with terrible force upon (\w+), shattering
    (\w+) aura of rebounding\.$
  type: 1
- pattern: ^You lunge toward (\w+) with (.+), but finding no resistance, you stumble hopelessly off balance\.$
  type: 1
- pattern: ^You lunge toward (\w+) with a (.+), but finding no resistance, you stumble hopelessly off balance\.$
  type: 1
- pattern: ^Lunging forward, you bring .+ down in a savage diagonal blow, carving through (\w+)'s aura of rebounding\.$
  type: 1
- pattern: ^Lunging forward, you bring a .+ down in a savage diagonal blow, carving through (\w+)'s aura of rebounding\.$
  type: 1
- pattern: ^With a wooping cackle the hyena lunges at (\w+), ripping apart \w+ aura of rebounding with \w+ mighty jaws\.$
  type: 1
]]--

if type(target) == "string" and isTargeted(matches[2]) then
	tAffs.rebounding = false
	tAffs.shield = false
	-- V2 tracking support
	if ataxia and ataxia.settings and ataxia.settings.useAffTrackingV2 then
		if removeAffV2 then
			removeAffV2("rebounding")
			removeAffV2("shield")
		elseif tAffsV2 then
			tAffsV2.rebounding = 0
			tAffsV2.shield = 0
		end
	end
	selectString(line,1)
	setBold(true)
	fg("NavajoWhite")
	resetFormat()
end

if matches[2] == target then
	tAffs.rebounding = false
	tAffs.shield = false
	-- V2 tracking support
	if ataxia and ataxia.settings and ataxia.settings.useAffTrackingV2 then
		if removeAffV2 then
			removeAffV2("rebounding")
			removeAffV2("shield")
		elseif tAffsV2 then
			tAffsV2.rebounding = 0
			tAffsV2.shield = 0
		end
	end
end
