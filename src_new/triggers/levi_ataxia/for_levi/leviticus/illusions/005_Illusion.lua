--[[mudlet
type: trigger
name: Illusion
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- Illusions
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
- pattern: '** Illusion **'
  type: 3
- pattern: Illusion
  type: 1
]]--

tAffs.rebounding = false
if removeAffV3 then removeAffV3("rebounding") end
tAffs.shield = false
if removeAffV3 then removeAffV3("shield") end
tshield = false
trebounding = false
tAffs.curseward = false
if removeAffV3 then removeAffV3("curseward") end

-- Illusion detected; undo any shield set on the next 2 lines
tempLineTrigger(1, 1, [[tAffs.shield = false; if tAffsV2 then tAffsV2.shield = 0 end]])
if removeAffV3 then removeAffV3("shield") end
tempLineTrigger(2, 1, [[tAffs.shield = false; if tAffsV2 then tAffsV2.shield = 0 end]])
if removeAffV3 then removeAffV3("shield") end