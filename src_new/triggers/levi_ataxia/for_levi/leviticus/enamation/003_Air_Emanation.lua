--[[mudlet
type: trigger
name: Air Emanation
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
- pattern: ^You sweep an? \w+ staff over your head and a great wind rises, picking up
  type: 1
]]--

-- AIR EMANATION: "your target will be struck down with paralysis and dizziness, as well as being
-- stunned for a short time. If they already have dizziness, they will be given asthma instead."
-- (Elementalism.wiki:242).
--   * Dizziness is recorded either way: a target that had it keeps it. Asthma is added only when
--     we already believed the target dizzy (v4.7.420; before, the emanation never gave asthma).
--   * The stun is not recorded. Its length is unstated ("a short time"), stun is not one of the
--     game's afflictions (AFFLICTION SHOW), and no decision reads a target's stun (the one trigger
--     that records it, 770_Battlecry_Stun, never clears it).
--
-- THE LINE IS ABOUT 160 COLUMNS, and this user's server wraps at 119-124 (CLAUDE.md, v4.7.351).
-- The old pattern was the whole line, folded across two YAML lines where tools/check_wrap.py could
-- not see it (kb/CONFLICTS.md #2), so this trigger never fired. Since v4.7.420 it matches the
-- opening words, as the water emanation (002) does; the rows are joined until the sentence closes
-- and the target's name is read from that. Every row of the cast is highlighted; only our target
-- is recorded.
local function record()
  local dizzy = haveAff("dizziness")   -- before this cast's own dizziness is recorded
  tarAffed("paralysis")
  tarAffed("dizziness")
  if dizzy then tarAffed("asthma") end
  magi.offense = magi.offense or {}
  magi.offense.ptRelay(target .. ": Emanation Air (Paralysis + " .. (dizzy and "Asthma" or "Dizziness") .. ")")
end

local function paint()
  selectCurrentLine() bg("cyan")
end

-- `text` is the sentence so far. Act once it has closed with the name in it; otherwise read the
-- next row (at most two more).
local function read(text, left)
  local tgt = text:match("picking up (%w+) and dashing them violently about before casting them back to the ground%.")
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
