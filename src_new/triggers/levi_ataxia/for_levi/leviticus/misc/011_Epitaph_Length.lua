--[[mudlet
type: trigger
name: Epitaph Length
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Classes K-S
- Pariah
- Misc
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
- pattern: ^Your epitaph now consists of (\d+) logographs?\.$
  type: 1
]]--

ataxia.vitals.epitaph = tonumber(matches[2])
if ataxiaBasher.enabled then
  if not ataxiaBasher.manual then
    deleteFull()
  end
else
  selectString(line, 1)
  if ataxia.vitals.epitaph < 2 then
    fg("DimGrey")
    pariah.expose = false
  else
    fg("DarkSlateGrey")
    pariah.expose = true
  end
  deselect()
  resetFormat()
end
