--[[mudlet
type: trigger
name: Waterbond on
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- Mage
- Staffcast
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
- pattern: ^Even as the wave of cold dissipates, you retain control over the fluid and send it spinning through the air to
    bind (\w+) in a watery web\.$
  type: 1
]]--

if isTargeted(matches[2]) then
twaterbond = true
  -- How long the bonds hold depends on how cold the target already is.
  local bondFor = 15
  if tAffs.frozen then bondFor = 45
  elseif tAffs.shiving then bondFor = 35
  elseif tAffs.nocaloric then bondFor = 25
  end
  tempTimer(bondFor, [[twaterbond = false]])
ataxia_tarAffTimed("waterbond", bondFor)
if partyrelay and not ataxia.afflictions.aeon then send("pt " ..target.. ": Waterbond") end
end
  
  