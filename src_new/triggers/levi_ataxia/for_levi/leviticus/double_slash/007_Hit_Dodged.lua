--[[mudlet
type: trigger
name: Hit Dodged
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Classes K-S
- Double Slash
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
- pattern: ^(\w+) twists \w+ body out of harm\'s way\.$
  type: 1
- pattern: ^(\w+) quickly jumps back, avoiding the attack.$
  type: 1
- pattern: ^(\w+) dodges nimbly out of the way.$
  type: 1
- pattern: ^A reflection of (\w+) blinks out of existence.$
  type: 1
- pattern: The attack rebounds back onto you!
  type: 3
- pattern: ^You lash out at (\w+) with (.+), but miss\.$
  type: 1
]]--

-- Check if this is rebounding specifically
local isRebounding = (line == "The attack rebounds back onto you!")

-- If rebounding, we need to undo the affliction that was just tracked
-- because the attack didn't actually land
if isRebounding and ataxiaTemp.lastAffAdded then
    erAff(ataxiaTemp.lastAffAdded)
    -- V2 support: also remove from V2 tracking
    if removeAffV2 then removeAffV2(ataxiaTemp.lastAffAdded) end
    ataxiaEcho("[REBOUND] Attack rebounded - removed " .. ataxiaTemp.lastAffAdded .. " from tracking")
    -- If it was exploit (weariness+paranoia), also remove paranoia
    if ataxiaTemp.lastAffAddedExtra then
        erAff(ataxiaTemp.lastAffAddedExtra)
        if removeAffV2 then removeAffV2(ataxiaTemp.lastAffAddedExtra) end
    end
    ataxiaTemp.lastAffAdded = nil
    ataxiaTemp.lastAffAddedExtra = nil
    -- DON'T increment hitCount on rebound - the attack didn't land
    -- Also decrement hitCount since the swing trigger already incremented it
    ataxiaTemp.hitCount = ataxiaTemp.hitCount - 1
    return
end

ataxiaTemp.hitCount = ataxiaTemp.hitCount + 1
