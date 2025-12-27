--[[mudlet
type: trigger
name: Parried
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Affs Post Queue - Gated
- Limb Got Hit
- Limb Hits Unorganised
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
- pattern: ^(\w+) parries the attack with a deft manoeuvre.$
  type: 1
- pattern: ^One of the tongues that you have mutated lashes out at (\w+), but \w+ ducks back out of its reach.$
  type: 1
- pattern: ^(\w+) steps into the attack, grabs your arm, and throws you violently to the ground.$
  type: 1
]]--

if isTargeted(matches[2]) then
  
	tAffs.paralysis = nil
	tAffs.prone = nil
  tAffs.numbedleftarm = nil
	selectString(line, 1)
	fg("black")
	bg("DarkSlateBlue")
	resetFormat()
	
	if ataxia_isClass("Runewarden") or ataxia_isClass("Infernal") or ataxia_isClass("Paladin") or ataxia_isClass("Unnamable") then
		erAff("nausea")
  elseif ataxia_isClass("Blademaster") then  
    if bmFistTimer then killTimer(bmFistTimer) end
		tAffs.airfist = nil           
	end
 -- if ataxiaTemp.lastLimbHit then
    --ataxiaTemp.parriedLimb = ataxiaTemp.lastLimbHit
    --cecho("<green> -> "..ataxiaTemp.parriedLimb) 
 -- end
end