--[[mudlet
type: trigger
name: CEASE FORM
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- DRAGON
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
- pattern: You cease your transformation into Dragonform.
  type: 3
- pattern: Your draconic form melts away, leaving you suddenly weaker and more vulnerable.
  type: 3
]]--

ataxia.settings.paused = false
ataxiaEcho("System has been "..(ataxia.settings.paused and "<red>paused." or "<green>unpaused."))
send("curing priority defence list reset")
if gmcp.Char.Status.class == "Infernal" then
expandAlias("defup isnb")
send("mastery on;hyena recall;order hyena follow me")
elseif gmcp.Char.Status.class == "Apostate" then
expandAlias("defup apoo")
send("summon baalzadeen;summon daegger")
elseif gmcp.Char.Status.class == "Runewarden" then
expandAlias("defup rdwb")
elseif gmcp.Char.Status.class == "Earth Lord" then
expandAlias("defup earth")
end