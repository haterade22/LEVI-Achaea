--[[mudlet
type: trigger
name: LIMB DAMAGE PARTY
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- PARTY TARGETTING
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
- pattern: '^\(Party\): (\w+) says, "(\w+): (\w+) (\d+)\%\."'
  type: 1
- pattern: '^\(Party\): (\w+) says, "(\w+): (\w+) (\w+) (\d+)\%\."'
  type: 1
]]--

if isTargeted(matches[3]) then
if matches[4] == "head" then tLimbs.H = tLimbs.H + matches[5] end
if matches[4] == "torso" then tLimbs.T = tLimbs.T + matches[5] end
if matches[4] == "right" and matches[5] == "leg" then tLimbs.RL = tLimbs.RL + matches[6] end
if matches[4] == "right" and matches[5] == "arm" then tLimbs.RA = tLimbs.RA + matches[6] end
if matches[4] == "left" and matches[5] == "leg" then tLimbs.LL = tLimbs.LL + matches[6] end
if matches[4] == "left" and matches[5] == "arm" then tLimbs.LA = tLimbs.LA + matches[6] end

end


