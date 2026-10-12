--[[mudlet
type: trigger
name: Disrupt
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Affs Post Queue - Gated
- Classes K-S
- Monk
- Telepathy/Tekura
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
- pattern: ^You quickly attack (\w+)'s mind from multiple directions, upsetting \w+ equilibrium.$
  type: 1
]]--

if isTargeted(matches[2]) then
  -- AFFLICTION SHOW gives disrupted no duration: it lasts until the target CONCENTRATEs, which 788
  -- sees. The 10 s is a backstop for a concentrate we miss, not a game duration. A raw timer here
  -- was not restarted by a re-disrupt, so the first one's clock erased the second.
  ataxia_tarAffTimed("disrupted", 10)
  if partyrelay then
    send("pt disrupt on "..matches[2],false)
  end  
end