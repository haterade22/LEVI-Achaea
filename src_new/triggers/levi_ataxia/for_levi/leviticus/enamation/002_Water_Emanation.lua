--[[mudlet
type: trigger
name: Water Emanation
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- Mage
- Enamation
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
- pattern: ^The might of elemental Water surging through your body, you make the slightest flick with a primordial staff,
    and the hand of Sllshya descends as a freezing deluge to smash (\w+)\.$
  type: 1
]]--

if tAffs.nocaloric == true and tAffs.shivering then
tarAffed("shivering")
tarAffed("disrupted")
tarAffed("frozen")
  if partyrelay and not ataxia.afflictions.aeon then send("pt " ..target.. ": Shivering, Disrupted and Frozen") end
elseif tAffs.nocaloric == true and not tAffs.shivering then
tarAffed("shivering")
tarAffed("disrupted")
  if partyrelay and not ataxia.afflictions.aeon then send("pt " ..target.. ": Shivering and Disrupted") end
else
tarAffed("nocaloric")
tarAffed("disrupted")
  if partyrelay and not ataxia.afflictions.aeon then send("pt " ..target.. ": Disrupted") end
end