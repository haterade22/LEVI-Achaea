--[[mudlet
type: trigger
name: Fire Emanation
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- Mage
- Enamation
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
- pattern: ^The might of elemental Fire filling you like a scorching river, you lift an? \w+ staff to point at (\w+)
    and unleash a stream of searing flame\.$
  type: 1
]]--

local tgt = matches[2]
if tgt ~= target then return end
-- Emanation Fire: +2 burns (cap 5), track in magi.offense.state
magi.offense = magi.offense or {}
magi.offense.state = magi.offense.state or {}
magi.offense.state.burns = math.min((magi.offense.state.burns or 0) + 2, 5)
tburns = magi.offense.state.burns -- backward compat
tarAffed("burning")
magi.offense.ptRelay(target .. ": Emanation Fire (burns " .. magi.offense.state.burns .. "/5)")
cecho(" <DimGrey>[<red>" .. magi.offense.state.burns .. "/5<DimGrey>]")
selectCurrentLine() bg("cyan")