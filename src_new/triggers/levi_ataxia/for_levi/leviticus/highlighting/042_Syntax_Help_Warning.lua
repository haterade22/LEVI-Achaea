--[[mudlet
type: trigger
name: Syntax Help Warning
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
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
- pattern: ^Syntax:$
  type: 1
]]--

-- A SYNTAX BLOCK IS THE GAME REJECTING A COMMAND -- and when we did not type one, it is
-- rejecting OURS.
--
-- This exists because the same bug shipped twice in one day, both times silently:
--   * v4.7.203  `M._relatchBoons` sent bare `BOONS`. Valid forms are BOON CLAIMED / OPTIONS /
--               CLAIM / CONTEMPLATE. The boon re-latch had done NOTHING since v4.7.188 --
--               through three separate passes over that function, one of them an adversarial
--               review, all of which reasoned about WHEN to send and never about WHAT.
--   * v4.7.209  `M._bardPerformanceCheck` sent bare `PERFORMANCE`. Valid forms are
--               PERFORMANCE SHOW / END / SUSPEND / RESUME. Worse than a no-op: the probe
--               never got an answer, so it timed out and RECOMPOSED on every single ripple.
--
-- Both were found only because the user noticed a syntax block in a log. Nothing in the
-- package reacted to it, and a rejected command is otherwise perfectly silent -- there is no
-- error, no missing state, just a feature that quietly does nothing forever.
--
-- So: make it loud. This does not try to identify the command (the syntax block does not name
-- it, and guessing from the following lines would be fragile). It just refuses to let the one
-- visible symptom scroll past unremarked.
--
-- FALSE POSITIVES ARE FINE HERE. Typing a command wrong yourself also prints this, and being
-- told so is useful rather than annoying. Throttled to once every 3s so a HELP page cannot
-- spam the console.
selectString(line, 1)
setBold(true)
fg("indian_red")
deselect()
resetFormat()

ataxiaTemp = ataxiaTemp or {}
local nowT = (getEpoch and getEpoch()) or 0
if nowT ~= ataxiaTemp.syntaxWarnAt then
  ataxiaTemp.syntaxWarnAt = nowT
  if ataxiaEcho then
    ataxiaEcho("<indian_red>SYNTAX<reset> -- a command was rejected. If you did not type one, "
      .. "the system sent something invalid.")
  end
end
