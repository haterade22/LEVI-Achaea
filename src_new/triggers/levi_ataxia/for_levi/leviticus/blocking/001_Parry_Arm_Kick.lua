--[[mudlet
type: trigger
name: Parry Arm Kick
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- MONK 1
- Monk
- Shikudo Triggers
- Shikudo
- Blocking
attributes:
  isActive: 'yes'
  isFolder: 'no'
  isTempTrigger: 'no'
  isMultiline: 'yes'
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
- pattern: ^You lash out with a straight kick at the (left|right) shoulder of (\w+).$
  type: 1
- pattern: '1'
  type: 5
- pattern: ^(\w+)  parries the attack with a deft manoeuvre.$
  type: 1
]]--

-- multimatches[1][2] = "left" or "right" from first pattern
local arm = multimatches[1][2]

if arm == "left" then
  tpla = true
  tpra = false
else
  tpra = true
  tpla = false
end

tpll = false
tph = false
tpto = false
tprl = false

-- Set frontkick parry flag for Rain form combo switching
if ataxia.vitals.form == "Rain" then
  ataxiaTemp.frontkickWasParried = true
end
