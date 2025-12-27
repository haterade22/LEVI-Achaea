--[[mudlet
type: trigger
name: Hyperfocus Detection
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Class Stuff
- Monk
- Shikudo
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
- pattern: ^You will now focus on bypassing attempts to deflect blows when striking the (.+).$
  type: 1
]]--

ataxiaTemp.hyperLimb = matches[2]:lower()
cecho("\n     <green>-[ <DimGrey>Hyperfocus set to: <red>"..ataxiaTemp.hyperLimb.."<green> ]-")

--disableTrigger("Hyperfocus Detection")