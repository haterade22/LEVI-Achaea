--[[mudlet
type: trigger
name: Parry Leg Kick
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
- pattern: ^Snapping your leg out to its full extent, you drive a heel into the (left|right) knee of (\w+).$
  type: 1
- pattern: '1'
  type: 5
- pattern: ^(\w+) parries the attack with a deft manoeuvre.$
  type: 1
]]--

-- multimatches[1][2] = "left" or "right" from first pattern
local leg = multimatches[1][2]

if leg == "left" then
  tpll = true
  tprl = false
else
  tprl = true
  tpll = false
end

tpla = false
tph = false
tpto = false
tpra = false

-- Set flashheel parry flag for Willow form combo switching
if ataxia.vitals.form == "Willow" then
  ataxiaTemp.flashheelWasParried = true
end

-- Also set for Gaital form (which uses flashheel too)
if ataxia.vitals.form == "Gaital" then
  ataxiaTemp.flashheelWasParried = true
end
