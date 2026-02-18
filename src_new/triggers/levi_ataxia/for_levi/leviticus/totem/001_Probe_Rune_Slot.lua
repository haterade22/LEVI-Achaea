--[[mudlet
type: trigger
name: TC Probe Rune Slot
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- Totem
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
mFgColor: ''
mBgColor: ''
mSoundFile: ''
colorTriggerFgColor: '#000000'
colorTriggerBgColor: '#000000'
patterns:
- pattern: ^A rune (.+) is sketched in slot (\d+)\.$
  type: 1
]]--

if totemChecker and totemChecker.state and totemChecker.state.active
   and totemChecker.state.phase == "probing" then
  local runeDesc = matches[2]
  local slotNum = tonumber(matches[3])
  local runeName = totemChecker.runeDescToName[runeDesc] or "unknown"
  totemChecker.onProbeSlot(slotNum, runeName)
end
