--[[mudlet
type: trigger
name: Waterbond on
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- Mage
- Staffcast
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
- pattern: ^Even as the wave of cold dissipates, you retain control over the fluid
  type: 1
]]--

-- THE GLACIAL CRYSTAL'S WATERBOND. "If they are frozen, they shall last for 45 seconds. If they
-- are only shivering, they will last for 35 seconds. If they are neither shivering nor frozen but
-- lacking the insulation defence, they will last 25 seconds. Otherwise, they will only last 15
-- seconds." (kb/raw/wiki/Artificing.wiki:82). A stripped insulation is the target affliction
-- `nocaloric`.
--
-- v4.7.420: the shivering test read `tAffs.shiving`, a key nothing sets, so a shivering target was
-- given 25 or 15 seconds, never 35. All three tests now ask the tracker through haveAff, as
-- 021_Freeze and 015_Dehydrate do: tAffs is only V3's mirror, rewritten when an affliction passes
-- 30% or falls under 1% (syncToOldSystemV3), so between the two it keeps an old answer -- a frozen
-- that a cure has left at 20% is not frozen to haveAff, but can still be true there.
--
-- THE LINE IS 140 COLUMNS with a seven-letter name (134 at the least), and this user's server
-- wraps at 119-124 (CLAUDE.md, v4.7.351). The old pattern was the whole line, folded across two
-- YAML lines where tools/check_wrap.py cannot see it (kb/CONFLICTS.md #2), so this trigger never
-- fired: no waterbond was ever recorded, and lock mode (`cc`), which casts horripilation until it
-- sees one (or blistered, paralysis or anorexia), kept casting it. It now matches the opening
-- words; the name comes near the end, so it is read from the row that finishes the sentence (the
-- enamation/002 idiom).
local function bind(who)
  if not isTargeted(who) then return end
  twaterbond = true
  local bondFor = 15
  -- A hypothermic target is frozen. HYPOTHERMIA lands only "if your enemy is already frozen"
  -- (kb/raw/wiki/Elementalism.wiki:181), "Prevents curing the freezing affliction" and is
  -- cured with "Though still frozen, ..." (kb/raw/live/affliction_show/hypothermia.txt). V3 can
  -- hold it without frozen: both hypothermia lines (magi_offense_tracking/005,
  -- pummel-related/002) give frozen, and on a target V3 has not seen shivering,
  -- applyFrozenInteractionV3 records shivering instead. Without the hypothermia test, a freeze
  -- we did not see reads as "only shivering": 35 s, not 45 (v4.7.420). The fade line
  -- (staffcast/001) ends the bond exactly; this time is the backstop, and one that runs out
  -- early lets lock mode cast horripilation again at a target still bound.
  if haveAff("frozen") or haveAff("hypothermia") then bondFor = 45
  elseif haveAff("shivering") then bondFor = 35
  elseif haveAff("nocaloric") then bondFor = 25
  end
  tempTimer(bondFor, [[twaterbond = false]])
  ataxia_tarAffTimed("waterbond", bondFor)
  if partyrelay and not ataxia.afflictions.aeon then send("pt " ..target.. ": Waterbond") end
end

-- `text` is the sentence so far. Act once it names who is bound; otherwise read the next row (at
-- most two more).
local function read(text, left)
  local who = text:match("to bind (%w+) in a watery web")
  if who then return bind(who) end
  if left == 0 or text:match("%.%s*$") then return end
  tempLineTrigger(1, 1, function()
    read((text:gsub("%s+$", "")) .. " " .. (line:gsub("^%s+", "")), left - 1)
  end)
end

read(line, 2)
