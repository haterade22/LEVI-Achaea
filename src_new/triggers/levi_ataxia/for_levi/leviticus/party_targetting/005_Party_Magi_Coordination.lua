--[[mudlet
type: trigger
name: Party Magi Coordination
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
- pattern: ^\(Party\): (\w+) says, "Staffcast: (\w+)[.!]?"$
  type: 1
- pattern: ^\(Party\): (\w+) says, "(\w+): [Tt]ransfixed?[.!]?"$
  type: 1
- pattern: ^\(Party\): (\w+) says, "(\w+): TRANSFIXED[.!]?"$
  type: 1
- pattern: ^\(Party\): (\w+) says, "(\w+): [Uu]nblind[.!]?"$
  type: 1
]]--

-- Gate: only when playing Magi
if gmcp.Char.Status.class ~= "Magi" then return end
-- Don't react to our own callouts
if matches[2] == gmcp.Char.Name then return end

local tgt = matches[3]

if matches[1]:lower():find("unblind") then
  send("queue addclearfull freestand cast transfix " .. tgt)
else
  -- Staffcast call or Transfixed call
  send("queue addclearfull freestand staffcast horripilation at " .. tgt)
end
