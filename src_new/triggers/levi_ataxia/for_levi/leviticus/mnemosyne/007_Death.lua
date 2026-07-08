--[[mudlet
type: trigger
name: Mnemosyne Death
hierarchy:
- Levi_Ataxia
- Ataxia
- Mnemosyne
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
- pattern: ^You have been slain by (.+?)\.?$
  type: 1
]]--

-- Only report if a Mnemosyne run is in progress (M._inRun). If the event's own
-- death line differs from Achaea's generic slain message, add its pattern here.
if ataxia.mnemosyne._inRun() then
  ataxia.mnemosyne.reportDeath(matches[2])
end
