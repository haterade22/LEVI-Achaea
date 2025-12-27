--[[mudlet
type: trigger
name: Cracked Ribs
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- Runie
- RuneWarden
- SNB
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
- pattern: ^Bones are broken by the might of inguz as Valafar, a crimson-tinged hellforged longsword cleaves the flesh of
    (\w+)\.$
  type: 1
]]--

tarAffed("paralysis")
tarAffed("sensitivity")
if partyrelay and not ataxia.afflictions.aeon then
send("pt " ..target..": paralysis sensitivity")
end