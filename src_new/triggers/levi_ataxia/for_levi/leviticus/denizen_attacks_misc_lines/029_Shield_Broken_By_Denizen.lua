--[[mudlet
type: trigger
name: Shield Broken By Denizen
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Basher
- Bashing
- Basher Lines
- Denizen Attacks / Misc Lines
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
- pattern: your magical shield
  type: 0
]]--

-- v4.7.486: a denizen that breaks our shield is learned by name, so the last stand never trusts a
-- shield against it again (basher/001, ataxiaBasher_onShieldLine). The function ignores our own
-- lines ("Your movement causes...", "Your action causes..."), a rebound, and anyone who is not a
-- denizen in the room. Sample: "A small brown lemming rips apart your magical shield defence with
-- its claws." (kb/raw, the Grulk death).
if ataxiaBasher_onShieldLine then ataxiaBasher_onShieldLine(line) end
