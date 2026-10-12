--[[mudlet
type: trigger
name: Blisters
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Classes A-J
- Fire Lord
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
- pattern: ^Bending the might of Kkractle upon the pitiful (\w+), you command that \w+ burn from within.$
  type: 1
]]--

-- Blistered only. The second argument used to be "burns", which is not an affliction: tarAffed
-- maps it to a stack of "burning" (017, since v4.7.276) and skips the "tar afflicted" event for
-- the whole call, so this recorded a burn the line never names and hid the blister from every
-- listener. tAffs.burns is a numeric counter elsewhere (016_Targeting_Functions, mage/006). This is
-- the Fire Lord's line (Kkractle), and nothing in kb/ says it gives a burning stack; the "stack of
-- the ablaze affliction" on an already blistered target is the Magi's major fire resonance
-- (Elementalism.wiki:62), which 022 records.
if isTargeted(matches[2]) then
  tarAffed("blistered")

  if ataxiaTemp.blisterTimer then killTimer(ataxiaTemp.blisterTimer) end
  ataxiaTemp.blisterTimer = tempTimer(15, [[ erAff("blistered"); ataxiaEcho("Target no longer has blisters.")]])
end