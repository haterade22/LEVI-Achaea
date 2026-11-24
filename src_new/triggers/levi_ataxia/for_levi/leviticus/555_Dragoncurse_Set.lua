--[[mudlet
type: trigger
name: Dragoncurse Set
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Affs Post Queue - Gated
- Classes A-J
- Dragon
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
- pattern: ^You summon your ancient power and direct the curse of (\w+) to strike down (\w+) in (\d+) seconds.$
  type: 1
]]--

if isTargeted(matches[3]) then
	ataxiaTemp.dragoncurse = matches[2]
end

-- When the curse strikes, tell the party: "<target>: <curse>". Fixed in v4.7.518: the timer text had an
-- unbalanced quote, so it never ran; it also read `matches` when the timer fired (by then another
-- line's), and the PvE guard was given the curse, not the target. Capture both now, use a closure.
local curse, who, secs = matches[2], matches[3], tonumber(matches[4])
if secs and ataxia_partyCallAllowed(who) then
  tempTimer(secs, function() send("pt " .. who .. ": " .. curse) end)
end