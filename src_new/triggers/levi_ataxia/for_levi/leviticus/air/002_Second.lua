--[[mudlet
type: trigger
name: Second
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- Mage
- RESONANCE
- Air
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
- pattern: ^A vicious wind rises, lashing and flaying at the body of (\w+) to leave (.+) sensitive and raw\.$
  type: 1
]]--

if target == matches[2] then
  if tAffs.deaf == false then
  tarAffed("sensitivity")
    if partyrelay and not ataxia.afflictions.aeon then send("pt " ..target.. ": sensitivity") end
  else
    tAffs.deaf = false
  end
 
end