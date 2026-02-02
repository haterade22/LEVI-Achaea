--[[mudlet
type: trigger
name: HealthLeech
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- INFERNAL
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
- pattern: ^You whip Matsuhama's morningstar toward the \w+ \w+ of \w+.$
  type: 1
- pattern: ^You whip Matsuhama's morningstar toward the \w+ of \w+.$
  type: 1
]]--

if toppression == "torment" then
tarAffed("healthleech")
if applyAffV3 then applyAffV3("healthleech") end
end