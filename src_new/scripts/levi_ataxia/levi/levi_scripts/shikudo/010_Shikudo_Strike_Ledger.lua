--[[mudlet
type: script
name: Shikudo Strike Ledger
hierarchy:
- Levi_Ataxia
- LEVI
- Levi  Scripts
- Leviticus
- Shikudo Script - Levi
- Shikudo
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

-- SHIKUDO STRIKE LEDGER (phase 3a, v4.7.419): which strike an outcome line belongs to.
--
-- A Shikudo strike prints a strike line, a damage line when the blow does limb damage, and an
-- effect line when its affliction lands (kb/combat/shikudo.md, "The lines of each attack"). The
-- strike triggers (563-585) record from the damage line and the effect-line triggers
-- (3rd_person_shikudo/, calls/) from the effect line; both lines name the target. ONE effect line
-- names nobody, ruku to the arm's:
--   The staff connects to the right arm with a resounding crack, the limb flopping uselessly.
-- It prints on light and damaged hits alike, and is assumed to on absorbed ones, which no log has
-- shown yet (after all 47 rukus to the arm in Mystor's
-- vNTjvghY log, 14 of them undamaged; c.iJVmpL.txt:2588-2597 is a "ruku light right"), so a ruku
-- to the arm with no damage line was never recorded: the only trigger on the line, calls/004, was
-- switched off and had no target check.
--
-- The ledger keeps the strike in flight. 587 opens an entry on every strike line, 789 hands it each
-- line that can end a strike, and the prompt (318) expires it. It RECORDS only when a line confirms
-- the hit: in Mystor's six logs every one of 202 strikes with no damage line was followed at once by
-- an outcome line (174 effect lines, 17 parries, 8 fumbles, 3 damage lines). A strike that ends with
-- no line is a gap in what we know, not a hit to commit (a commit at the boundary could only add
-- phantoms), so it is counted in `unresolved`, and echoed with its text while
-- `shikudoLedger.debug` is on: that is how the next unseen outcome line gets captured.
--
-- An arm line the strike in flight cannot take is counted apart, in `refused` (with `lastRefused`
-- = { why, text }), and echoed the same way. A tail row that never arrived and a ruku wording no
-- log has shown both end there, and both record nothing, which is exactly what happened before
-- the ledger: without the count, broken and working would look the same.
--
-- A top-level global, so never saved (not under ataxia or ataxiaBasher); it holds no timer id and
-- keeps time with getEpoch().

shikudoLedger = shikudoLedger or {}
shikudoLedger.cur = nil                 -- the strike in flight; a reload drops it
shikudoLedger.unresolved = shikudoLedger.unresolved or 0
shikudoLedger.refused = shikudoLedger.refused or 0
shikudoLedger.MAX_AGE = 2               -- seconds from a strike line to an outcome line it can own
shikudoLedger.MAX_TAIL = 2              -- rows a wrapped strike line may add (they run to 147 columns)

-- Strike starts (plain prefixes) that may be committed with NO outcome line, each with what it
-- gives: { ["<start>"] = { "<affliction>", ... } }. EMPTY on purpose: no log has a strike that
-- landed silently (202 of 202 above). Add one only from a captured log of such a strike.
shikudoLedger.SILENT_COMMIT = {}

-- The lines 789 hands over, as line STARTS: a server wrap or a client suffix would defeat an end
-- anchor. attacker = kb/raw/logs/2026-10-11_shikudo-vs-runewarden-snb_attacker.txt.
local DAMAGE = "^As your blow lands with a crunch, you perceive that you have dealt "  -- attacker:376
local PARRY = "^(%a+) parries the attack with a deft manoeuvre"            -- attacker:444, after :440
local FUMBLE = "^You fumble your strike"                                      -- attacker:434, after :433
local SHIELD = "^A dizzying beam of energy strikes you as your attack rebounds off of " -- LcJC-rJ5:207
local ARM = "^The staff connects to the (%a+) arm with a resounding crack"     -- attacker:377, :2575
-- Effect lines that name the target. Their own triggers record them; here they only resolve the
-- strike, so `unresolved` counts strikes that really got no line.
local EFFECTS = {
  "^The staff cracks across the ",                      -- kuro (attacker:28)
  "^%a+ staggers as the staff cracks across ",          -- ruku to the torso (attacker:895)
  "^The breath of ",                                    -- livestrike (attacker:834)
  "^The staff smashes into the face of ",               -- hiraku (attacker:957)
  "^The staff connects to the side of ",                -- hiru (attacker:953)
  "^The end of the staff ",                             -- jinzuku (attacker:2669), needle (:2662)
  "^The end of your staff smashes the magical shield",  -- shatter (attacker:1111)
  "^Horror overcomes the face of ",                     -- nervestrike (vNTjvghY:185)
  "^The instep of your foot smashes into the ",         -- frontkick (attacker:362)
  "^Your foot catches ",                                -- risingkick to the head (attacker:839)
  "^Your foot drives into the solar plexus of ",        -- risingkick to the torso (attacker:1656)
  "^You feel the satisfying crunch of bone",            -- flashheel (attacker:72)
  "^The staff sweeps the legs out from under ",         -- sweep (attacker:2456)
}

local function finished(text)
  return text:find("%.%s*$") ~= nil
end

-- Does the strike text name our target as a whole word? A strike line ends with the name or puts
-- "'s", "," or " in a controlled arc" after it, so a letter on either side means another word.
local function namesTarget(text)
  if type(target) ~= "string" or target == "" then return false end
  local name = target:lower():gsub("%W", "%%%0")
  return (" " .. text:lower() .. " "):find("%A" .. name .. "%A") ~= nil
end

-- A ruku to THIS arm, in either of its strike lines (kb/combat/shikudo.md):
--   You spin a full rotation, bringing <staff> around in a blur of motion to smash into the right arm of <T>.
--   You whip <staff> at <T> in a controlled arc, bringing its length to crack against her right arm.
-- The first is attacker:440, a later strike of a combo; the second is the first strike, as 584
-- matches it (no log has it to the arm; attacker has it to the torso). Nervestrike also starts
-- "You whip", hence the arc.
local function rukuTo(text, side)
  local spun = text:find("^You spin a full rotation, bringing ") ~= nil
  local whipped = text:find("^You whip ") ~= nil and text:find(" in a controlled arc,", 1, true) ~= nil
  return (spun or whipped) and text:find(" " .. side .. " arm", 1, true) ~= nil
end

local function settle(cur, how)
  if cur and not cur.outcome then cur.outcome = how end
end

local function drop(cur, why)
  if cur then cur.dropped, cur.outcome = why, why end
end

-- Echoes stay ASCII, and a strike line must not open a cecho tag.
local function ascii(s)
  return (s:gsub("[^\32-\126]", "?"):gsub("[<>]", ""))
end

-- An arm line the strike in flight does not fit: the line came, so it is not `unresolved`, but it
-- was not recorded either. Returns false, for rukuArm to return.
local function refuse(cur, why)
  shikudoLedger.refused = (shikudoLedger.refused or 0) + 1
  shikudoLedger.lastRefused = { why = why, text = cur.text }
  if shikudoLedger.debug and ataxiaEcho then
    ataxiaEcho("Shikudo ledger: arm line not recorded (" .. why .. "): " .. ascii(cur.text))
  end
  return false
end

-- The target's name comes last in most strike lines, and a strike line runs to 147 columns against
-- this user's 119-124 wrap: "...to smash into the right arm of" / "Claes." (attacker:440 at 119). The
-- next row is read as the tail, the 071_Shaman_Curse_Highlight idiom. With no next row the entry
-- stays unfinished and records nothing: the cautious failure.
local function armTail(cur)
  if tempLineTrigger then
    tempLineTrigger(1, 1, function() shikudoLedger.more(line, cur) end)
  end
end

local function silentCommit(cur)
  for start, affs in pairs(shikudoLedger.SILENT_COMMIT) do
    if cur.text:sub(1, #start) == start then
      if cur.done and namesTarget(cur.text) then
        for _, aff in ipairs(affs) do tarAffed(aff) end
      end
      return
    end
  end
end

-- 587, on row 1 of every strike line. The previous strike's lines are over by now.
function shikudoLedger.strike(row)
  shikudoLedger.expire("strike")
  if not (ataxia_isClass and ataxia_isClass("monk")) then return end
  local cur = { text = row or "", at = getEpoch(), tail = 0 }
  cur.done = finished(cur.text)
  shikudoLedger.cur = cur
  if shikudoEcho and shikudoEcho.onStrike then shikudoEcho.onStrike() end -- the [SK] line (012)
  if not cur.done then armTail(cur) end
end

-- The next row of a strike line that was cut off (armTail). Only for the entry that asked.
function shikudoLedger.more(row, entry)
  local cur = shikudoLedger.cur
  if not cur or cur ~= entry or cur.done then return end
  local tail = (row or ""):gsub("^%s+", "")
  cur.text = cur.text .. " " .. tail
  cur.tail = cur.tail + 1
  cur.done = finished(cur.text)
  if not cur.done and cur.tail < shikudoLedger.MAX_TAIL then armTail(cur) end
end

-- 789, on every line that can end a strike. Returns what the line was (for the tests). A parry, a
-- fumble and a shield's rebound DROP the strike (attacker:440-444 is a parried ruku the logger's own
-- tracker recorded anyway); a damage or effect line resolves it; the arm line goes to rukuArm.
function shikudoLedger.outcome(text)
  text = text or ""
  local cur = shikudoLedger.cur
  if text:find(DAMAGE) then
    settle(cur, "damage")
    if shikudoEcho and shikudoEcho.onDamage then shikudoEcho.onDamage(text) end
    return "damage"
  end
  local who = text:match(PARRY)
  if who then
    if isTargeted(who) then drop(cur, "parry") end
    return "parry"
  end
  if text:find(FUMBLE) then
    drop(cur, "fumble")
    return "fumble"
  end
  if text:find(SHIELD) then
    drop(cur, "shield")
    return "shield"
  end
  local side = text:match(ARM)
  if side then
    shikudoLedger.rukuArm(side)
    return "arm"
  end
  for _, start in ipairs(EFFECTS) do
    if text:find(start) then
      settle(cur, "effect")
      return "effect"
    end
  end
  return nil
end

-- The arm line names no target, so it goes to the strike in flight, and only when that strike is an
-- undropped ruku to that arm, at our target, under MAX_AGE old. Recorded as 578/584 record the
-- damaged hit: clumsiness, or healthleech once the target is clumsy, with the same party relay.
function shikudoLedger.rukuArm(side)
  local cur = shikudoLedger.cur
  if ignoreThirdPerson then
    -- 578/584 recorded this hit from its damage line and set the flag. 587 clears it at every
    -- strike line, so it can only be this strike's: consume it, as the effect-line triggers do,
    -- and mark the strike recorded, so a second arm line cannot record it again.
    ignoreThirdPerson = nil
    settle(cur, "arm")
    if cur then cur.recorded = true end
    return false
  end
  -- No strike in flight (a non-monk opens none), one a parry, fumble or shield dropped, or one
  -- already recorded: nothing about this line is unknown.
  if not cur or cur.dropped or cur.recorded then return false end
  settle(cur, "arm")
  -- In this order: an unfinished text cannot be read for the arm or the name.
  if not cur.done then return refuse(cur, "unfinished") end
  if getEpoch() - cur.at > shikudoLedger.MAX_AGE then return refuse(cur, "stale") end
  if not rukuTo(cur.text, side) then return refuse(cur, "not a ruku to that arm") end
  if not namesTarget(cur.text) then return refuse(cur, "other target") end
  cur.recorded = true
  local clumsy = haveAff("clumsiness")
  if partyrelay then
    send("pt " .. target .. ": " .. (clumsy and "healthleech clumsiness" or "clumsiness"))
  end
  if clumsy then
    tarAffed("healthleech")
  else
    tarAffed("clumsiness")
  end
  return true
end

-- A new strike line or the prompt ends the strike. One with no outcome line is never recorded
-- (SILENT_COMMIT aside): it is counted, and echoed while shikudoLedger.debug is on.
function shikudoLedger.expire(why)
  local cur = shikudoLedger.cur
  if not cur then return end
  shikudoLedger.cur = nil
  if shikudoEcho and shikudoEcho.onStrikeEnd then shikudoEcho.onStrikeEnd(cur) end -- 012
  if cur.outcome then return end
  shikudoLedger.unresolved = (shikudoLedger.unresolved or 0) + 1
  shikudoLedger.lastUnresolved = cur.text
  silentCommit(cur)
  if shikudoLedger.debug and ataxiaEcho then
    ataxiaEcho("Shikudo ledger: no outcome line before the " .. tostring(why) .. ": " .. ascii(cur.text))
  end
end

-- 318, at every prompt, before it closes the gated window. One field read when nothing is pending.
function shikudoLedger.flush()
  if shikudoLedger.cur then shikudoLedger.expire("prompt") end
end

function shikudoLedger.current()
  return shikudoLedger.cur
end
