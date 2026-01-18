--[[mudlet
type: trigger
name: Mob Shielded
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Basher
- Bashing
- Basher Lines
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
- pattern: ^A nearly invisible magical shield forms around (.+)\.$
  type: 1
- pattern: ^A dizzying beam of energy strikes you as your attack rebounds off of (.+)'s shield\.$
  type: 1
- pattern: ^(\w+) rifles through a tome of the muses, a melodic composition spilling forth from \w+ lips\.$
  type: 1
]]--

local tar = matches[2]:lower()

if type(target) == "number" and ataxiaBasher.enabled and tar == secondTarget:lower() then
  bashConsoleEcho("denizen", "Coward shielded!")
  local argFound = false
  
  if not ataxiaBasher.shieldswap or ataxiaBasher_validTargets() <= 1 or ataxiaTemp.mobshieldtimer then
    ataxiaBasher.shielded = true
    removeShield = tempTimer( (secondTarget == "a mhun knight" and 4.5 or 3.1), [[ ataxiaBasher.shielded = false; removeShield = nil]]) 
  elseif ataxiaBasher.shieldswap and ataxiaBasher_validTargets() > 1 and not ataxiaTemp.mobshieldtimer then
    ataxiaBasher_shieldedTarget()
  end
  basher_needAction = true

	
elseif isTargeted(tar) then
	selectString(line, 1)
	fg("a_brown")
	resetFormat()
	tAffs.shield = true
	-- Update V2 tracking if available
	if tAffsV2 then
		tAffsV2.shield = 100
	end
end

