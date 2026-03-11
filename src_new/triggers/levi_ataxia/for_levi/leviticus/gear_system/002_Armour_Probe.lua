--[[mudlet
type: trigger
name: Armour Probe
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- Gear System
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
- pattern: ^(\d+): .+ \((paragon\d+)\)
  type: 1
]]--

-- Parses "probe armour" embrasure lines like:
-- 1: a resonate metalliferous paragon (paragon500167)     shifting damage protection (physical blunt)
-- Populates current slot state for skip-swap optimization

if ataxia and ataxia.armour and ataxia.armour.state and ataxia.armour.state.probing then
  local slotNum = tonumber(matches[2])
  local paragonId = matches[3]
  if slotNum and paragonId and slotNum >= 1 and slotNum <= 3 then
    ataxia.armour.state.currentSlots[slotNum] = paragonId
  end
end
