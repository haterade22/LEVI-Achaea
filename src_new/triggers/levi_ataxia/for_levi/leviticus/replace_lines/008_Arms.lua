--[[mudlet
type: trigger
name: Arms
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- Runie
- RuneWarden
- 2H
- Replace Lines
attributes:
  isActive: 'no'
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
conditonLineDelta: 1
mStayOpen: 0
mCommand: ''
packageName: ''
mFgColor: '#ff0000'
mBgColor: '#ffff00'
mSoundFile: ''
colorTriggerFgColor: '#000000'
colorTriggerBgColor: '#000000'
patterns:
- pattern: ^Taking hold of Apocalypse, a blackrock sword of black-hued steel with a firm two-handed grip, you hew savagely
    at (\w+)'s (left|right) arm.
  type: 1
]]--

deleteLine()
cecho("\n<purple>[<white>ARMSLASH<purple>]")

if evenom1 == "torment" and affstrack.score.healthleech>100 then
OppGainedAff("confusion")
elseif evenom1 == "torment" and affstrack.score.healthleech<50 then
OppGainedAff("healthleech")
elseif evenom1 == "exploit"  then
OppGainedAff("weariness")
OppGainedAff("paranoia")
end



