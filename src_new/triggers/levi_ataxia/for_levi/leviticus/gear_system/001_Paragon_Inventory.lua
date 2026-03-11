--[[mudlet
type: trigger
name: Paragon Inventory
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
- pattern: ^\s+(paragon\d+)\s+(.+)$
  type: 1
]]--

-- Parses "ii paragon" output lines like:
--     paragon514466           a crucious paragon
-- Registers each paragon in the armour management system

if ataxia and ataxia.armour and ataxia.armour.state and ataxia.armour.state.scanning then
  local id = matches[2]
  local name = matches[3]:match("^%s*(.-)%s*$") -- trim
  if id and name then
    ataxia.armour.registerParagon(id, name)
  end
end
