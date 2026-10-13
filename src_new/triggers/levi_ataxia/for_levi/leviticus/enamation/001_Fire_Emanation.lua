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
- pattern: ^The might of elemental Fire filling you like a scorching river, you lift
  type: 1
]]--

-- FIRE EMANATION: "your target will be given two stacks of the ablaze affliction."
-- (Elementalism.wiki:242). Ablaze is the game's other name for burning (AFFLICTION SHOW).
-- The offense's counter takes both stacks (two burns, capped at 5). The tracker (V3) is given
-- ONE application, as before, and on purpose: applyAffV3 raises its burning level by one per
-- application, and a body mending cures burning only at level 1 and never lowers a higher level
-- (only a target change or a disconnect resets it), so a second application would leave a burning
-- that outlives every mending. The price is the opposite error: after ONE mending V3 reads no
-- burning while a stack may remain. Recording both waits on V3 counting a mending down one stack
-- (open since v4.7.420). With a burn from another spell already on the target, even one
-- application takes the level past 1, with the same result.
--
-- THE LINE IS ABOUT 150 COLUMNS, and this user's server wraps at 119-124 (CLAUDE.md, v4.7.351).
-- The old pattern was the whole line, folded across two YAML lines where tools/check_wrap.py could
-- not see it (kb/CONFLICTS.md #2), so this trigger never fired. Since v4.7.420 it matches the
-- opening words, as the water emanation (002) does; the target's name sits in the middle and falls
-- on row 1 or 2 depending on the width, so the rows are joined until the sentence closes and the
-- name is read from that. Every row of the cast is highlighted; only our target is recorded.
local function paint()
  selectCurrentLine() bg("cyan")
end

local function record()
  magi.offense = magi.offense or {}
  magi.offense.state = magi.offense.state or {}
  magi.offense.state.burns = math.min((magi.offense.state.burns or 0) + 2, 5)
  tburns = magi.offense.state.burns -- backward compat
  tarAffed("burning")   -- one application, not two: see above
  magi.offense.ptRelay(target .. ": Emanation Fire (burns " .. magi.offense.state.burns .. "/5)")
  cecho(" <DimGrey>[<red>" .. magi.offense.state.burns .. "/5<DimGrey>]")
  paint()   -- again, so the counter just echoed onto this row is highlighted with it, as before
end

-- `text` is the sentence so far. Act once it has closed with the name in it; otherwise read the
-- next row (at most two more).
local function read(text, left)
  local tgt = text:match("staff to point at (%w+) and unleash a stream of searing flame%.")
  if tgt then
    if tgt == target then record() end
    return
  end
  if left == 0 or text:match("%.%s*$") then return end
  tempLineTrigger(1, 1, function()
    paint()
    read((text:gsub("%s+$", "")) .. " " .. (line:gsub("^%s+", "")), left - 1)
  end)
end

paint()
read(line, 2)
