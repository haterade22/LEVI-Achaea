--[[mudlet
type: trigger
name: Druid Cheese
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- Defence
- Druid
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
- pattern: Your \w+ \w+ is greatly damaged from the beating.(\w+) slowly pulls back .+, readying \w+ for a devastating strike.
  type: 1
- pattern: '1'
  type: 5
- pattern: \w+ slowly pulls back .+, readying \w+ for a devastating strike.
  type: 1
]]--

if gmcp.Char.Status.class == "Runewarden" or gmcp.Char.Status.class == "Infernal" then
send("wield bastard;arc " ..matches[2].. " curare")
end


ataxia_boxEcho("SHATTER CHEESE SHATTER CHEESE", "yellow")
ataxia_boxEcho("FREEZE || POUND INCOMING", "goldenrod")