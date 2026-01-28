--[[mudlet
type: trigger
name: DWC Parry Detected
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Remove Afflictions
- Groups
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
- pattern: ^(\w+) parries the attack with a deft manoeuvre\.$
  type: 1
]]--

-- Notify DWC vivisect systems of parry detection
-- Each system reads its own state.lastTargetedLimb to know which limb was parried
if isTargeted(matches[2]) then
    if infernalDWC and infernalDWC.onParry then
        infernalDWC.onParry()
    end
    if infernalDWC2L and infernalDWC2L.onParry then
        infernalDWC2L.onParry()
    end
end
