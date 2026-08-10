--[[mudlet
type: trigger
name: Icewall
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- Highlighting
attributes:
  isActive: 'yes'
  isFolder: 'no'
  isTempTrigger: 'no'
  isMultiline: 'no'
  isPerlSlashGOption: 'no'
  isColorizerTrigger: 'yes'
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
mFgColor: '#55ffff'
mBgColor: '#ffffff'
mSoundFile: ''
colorTriggerFgColor: '#000000'
colorTriggerBgColor: '#000000'
patterns:
- pattern: ^An icewall is here, blocking passage to the (.+)\.$
  type: 1
]]--

 selectString(line,1)
  setBold(true)
  fg("royal_blue")
  deselect()
  resetFormat()

-- GROUND TRUTH FOR THE WALL (v4.7.243). Until now this line was highlight-only, and
-- `S.wallRaised` was written in exactly one place: optimistically, from our OWN escape send
-- (`_escapeSuffix`). So a wall we did not place -- an affix's, a denizen's, or one of ours that
-- survived a reload -- was invisible to both of its consumers: `S.moveVerb`, which decides
-- BACKFLIP vs LEAP (only LEAP is confirmed to clear an icewall), and `S._panicDir`, which avoids
-- tumbling into a walled edge. The Kuthalebak death log has the room reporting a north wall while
-- our own state knew nothing about it.
--
-- The room description names the direction, so take it from there. Keyed on the Mnemosyne map's
-- current room, which is nil outside the tower -- that is what keeps real-world rooms out of the
-- table, without needing a second area check.
do
  local S = ataxia and ataxia.mnemosyne and ataxia.mnemosyne.swarm
  local MAP = ataxia and ataxia.mnemosyne and ataxia.mnemosyne.map
  local cur = MAP and MAP.current
  local dir = matches and matches[2]
  if S and cur and dir then
    dir = dir:lower():gsub("^%s+", ""):gsub("%s+$", "")
    S.wallRaised = S.wallRaised or {}
    S.wallRaised[cur] = dir -- LONG form, which is what wallRaised stores
  end
end