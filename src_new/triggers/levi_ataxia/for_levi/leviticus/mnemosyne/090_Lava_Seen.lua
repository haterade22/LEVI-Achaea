--[[mudlet
type: trigger
name: Lava Seen
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Mnemosyne
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
- pattern: Molten lava bubbles and churns.
  type: 0
]]--

-- A LAVA ROOM'S DESCRIPTION, live-captured 2026-09-18 -- seen through a GLANCE before we step
-- in, which is the whole point:
--
--   Glancing to the south, you see:
--   A long corridor. (indoors)
--   Molten lava bubbles and churns. The nebulous form of a phantom grizzly bear lumbers here. ...
--   You see exits leading north and east.
--
-- SUBSTRING, because the description line is long and wraps at the player's width (v4.7.286);
-- the phrase opens the line, so it is never the part that gets split.
--
-- Decides nothing on its own. Inside a pending glance it marks that glance as lava so the
-- explorer can PLAN the pass-through door from the exits line that follows (008 `_glanceResolve`
-- -> `ataxiaTemp.mnemLavaPlan` -> consumed by `M.onLava` on the splash). Outside a glance --
-- our own room's description on entry or LOOK -- it does nothing, because `MAP.current` may not
-- have advanced yet under gmcp/text ordering and the splash line (mnemosyne/064) is the
-- authority a moment later anyway. One sample of the wording; if a lava room ever describes
-- itself differently, this is the pattern to widen.
if ataxia and ataxia.mnemosyne and ataxia.mnemosyne.onLavaSeen then
  ataxia.mnemosyne.onLavaSeen()
end
