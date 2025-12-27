--[[mudlet
type: trigger
name: Flick
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Classes A-J
- Bard
- Bard Rework
- Blade Dance
attributes:
  isActive: 'yes'
  isFolder: 'no'
  isTempTrigger: 'no'
  isMultiline: 'yes'
  isPerlSlashGOption: 'no'
  isColorizerTrigger: 'no'
  isFilterTrigger: 'no'
  isSoundTrigger: 'no'
  isColorTrigger: 'no'
  isColorTriggerFg: 'no'
  isColorTriggerBg: 'no'
triggerType: 0
conditonLineDelta: 1
mStayOpen: 0
mCommand: ''
packageName: ''
mFgColor: '#ff0000'
mBgColor: '#ffff00'
mSoundFile: ''
colorTriggerFgColor: '#000000'
colorTriggerBgColor: '#000000'
patterns:
- pattern: ^You flick out with the point of .+, song blessed steel singing a keening note towards \w+.$
  type: 1
- pattern: '1'
  type: 5
- pattern: ^.*$
  type: 1
]]--

local person = target

if multimatches[3][1] == "The attack rebounds back onto you!" then
  tarAffed("rebounding")
elseif multimatches[3][1] == person .. " dodges nimbly out of the way." 
		or multimatches[3][1] == person .. " parries the attack with a deft manoeuvre." 
		or multimatches[3][1] == person .. " steps into the attack, grabs your arm, and throws you violently to the ground." 
		or multimatches[3][1] == person .. " quickly jumps back, avoiding the attack."  
		or multimatches[3][1] == "A reflection of " .. person .. " blinks out of existence." 
		or multimatches[3][1] == person .. " moves into your attack, knocking your blow aside before viciously countering with a strike to your head." 
		or multimatches[3][1] == person .. " twists his body out of harm's way."
		or multimatches[3][1] == person .. " twists her body out of harm's way."
	then
		if multimatches[3][1] == person .. " parries the attack with a deft manoeuvre." then
      if numbedLeft then killTimer(numbRight) end
      tAffs.numbedleftarm = nil
      ataxiaTemp.parriedLimb = ataxiaTemp.lastLimbHit
      cecho("<green> -> "..ataxiaTemp.parriedLimb)       
		end 
else

if bardtempo == "front" then
  if tAffs.crescendo == 0 or tAffs.crescendo == false then
    tAffs.crescendo = 1
  elseif tAffs.crescendo == 1 then
    tAffs.crescendo = 2
  elseif tAffs.crescendo == 2 then
    tAffs.crescendo = 3
  elseif tAffs.crescendo == 3 then
    tAffs.crescendo = 4
  elseif tAffs.crescendo == 4 then
    tAffs.crescendo = 5
  elseif tAffs.crescendo >= 5 then
    tAffs.crescendo = 5
  end
     
elseif bardtempo == "side" then
  tarAffed("earworm")
elseif bardtempo == "back" then
  if tAffs.crescendo == 0 or tAffs.crescendo == false then
    tAffs.crescendo = 1
  elseif tAffs.crescendo == 1 then
    tAffs.crescendo = 2
  elseif tAffs.crescendo == 2 then
    tAffs.crescendo = 3
  elseif tAffs.crescendo == 3 then
    tAffs.crescendo = 4
  elseif tAffs.crescendo == 4 then
    tAffs.crescendo = 5
  elseif tAffs.crescendo >= 5 then
    tAffs.crescendo = 5
  end
  tarAffed("earworm")
end
    
end


bardtemposequence = bardtemposequence + 1

