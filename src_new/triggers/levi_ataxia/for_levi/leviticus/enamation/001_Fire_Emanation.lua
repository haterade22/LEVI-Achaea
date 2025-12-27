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
- pattern: ^The might of elemental Fire filling you like a scorching river, you lift a primordial staff to point at (\w+)
    and unleash a stream of searing flame\.$
  type: 1
]]--

if partyrelay and not ataxia.afflictions.aeon then send("pt " ..target.. ": Burning (ablaze)") end
  if tburns == 0 or nil then
     tburns = 2
  elseif tburns == 1 then
    tburns = 3
  elseif tburns == 2 then
    tburns = 4
  elseif tburns == 3 then
    tburns = 5
  elseif tburns == 4 then
    tburns = 5
  elseif tburns == 5 then
	tburns= 5
  end
cecho(" <DimGrey>[<red>"..tburns.."/5<DimGrey>]")