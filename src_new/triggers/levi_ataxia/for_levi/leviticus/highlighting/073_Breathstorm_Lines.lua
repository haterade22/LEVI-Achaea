--[[mudlet
type: trigger
name: Breathstorm Lines
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
- pattern: ^Drawing a mighty breath to fill your lungs, you crane your neck backwards
  type: 1
- pattern: ^Clouds of draconic fury already exist here\.$
  type: 1
]]--

-- BREATHSTORM, both outcomes (live capture 2026-10-22, Golden Dragon):
--   cast:    "Drawing a mighty breath to fill your lungs, you crane your neck backwards and send a
--             screaming volley of psi-infused vapour into the air."  (the breath word changes by
--             colour, so the pattern stops before it)
--   refused: "Clouds of draconic fury already exist here."
-- THE CAST PATTERN IS GOLDEN DRAGON ONLY (user: "the cast line is specific to golden, so other
-- dragons would be different"). No other colour's cast line is captured; add each one as another
-- `- pattern:` here (its opening words, stopping before any colour word). Nothing depends on the
-- cast line firing: without it the send stamp still marks the room and the 3s hold still ends,
-- so it only ends the replay sooner. The refusal names no colour, so it should serve every colour.
-- Either way THIS ROOM HAS A STORM: ataxiaBasher_dragonStormMark (basher/002) records the room and
-- releases the in-flight hold, so the queued cast is not sent again. A refusal also means our room
-- key was wrong or the clouds outlived our visit, so it restarts the 10s floor too.
local refused = line:find("^Clouds of draconic fury") ~= nil
selectString(line, 1)
setBold(true)
fg(refused and "dim_grey" or "orange_red")
deselect()
resetFormat()

if ataxiaBasher_dragonStormMark then
	ataxiaBasher_dragonStormMark(refused)
end
