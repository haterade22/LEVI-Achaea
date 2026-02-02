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
  if tAffs.frozen then
    tempTimer(45, [[twaterbond = false]])
  elseif tAffs.shiving then
    tempTimer(35, [[twaterbond = false]])
  elseif tAffs.nocaloric then
    tempTimer(25, [[twaterbond = false]])
  else
  tempTimer(15, [[twaterbond = false]])
  end
tarAffed("waterbond")
if applyAffV3 then applyAffV3("waterbond") end
if partyrelay and not ataxia.afflictions.aeon then send("pt " ..target.. ": Waterbond") end
end
  
  