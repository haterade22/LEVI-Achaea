--[[mudlet
type: trigger
name: ASSAULT
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Affs Post Queue - Gated
- Classes K-S
- Knight
- Dual Blunt
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
- pattern: ^Whirling both of your weapons above your head, you unleash a vicious assault at the (\w+) of (\w+).$
  type: 1
]]--

if isTargeted(matches[3]) then if matches[2] == "head" then tLimbs.H = tLimbs.H + 100 elseif matches[2] == "torso" then tLimbs.T = tLimbs.T + 100 end end

if matches[2] == torso then
ataxiaTemp.fractures.crackedribs = 3
end