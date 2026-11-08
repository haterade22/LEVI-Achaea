--- attackers.lua -- the attacker of the whole-fight engine. Stage 1 has the scripted attacker only.
-- Pure Lua 5.1: no Mudlet calls, no files, no globals. tools/sim/fight.lua runs it.
--
-- A script is a list of actions, one per balance:
--   dstab <venom> <venom>        two venoms (rule attack.dstab.venoms); a shield blocks it, rebounding sends it back
--   flay shield [venom]          strips the shield, and the sileris coating with it (rules attack.flay,
--   flay rebounding [venom]      attack.flay.coating); the venom lands only when neither shield nor rebounding is left.
--                                When the named defence is not there, it strips the coating as a bare FLAY does (rule
--                                attack.flay.missing; model.flayMissing "nothing" runs its alternative, X 5328)
--   flay [venom]                 a bare FLAY strips the sileris coating (Subterfuge.wiki:76). With model.flayOrder
--                                "auto" it strips the shield, else rebounding, else the coating (rule attack.flay.order)
--   bite <venom>                 one venom; sileris blocks it (rule attack.bite)
--   impulse <suggestion> <venom> the suggestion lands, then a bite of the venom in the same packet (rules
--                                attack.impulse, attack.impulse.venom: 13 of 13 in the 2026-11-07 spar). The suggestion
--                                is one of model.suggestions, the trivial ones (rule attack.impulse.suggestions). It
--                                needs the attacker's equilibrium as well as its balance. It spends equilibrium
--                                (attack.cost.own.impulse_eq), and the bite's balance sets the next action. A shield
--                                blocks all of it; sileris blocks the bite only.
--   give <aff> [aff ...]         the named afflictions land at once, with no attacker line (rule attack.give)
--   wait <seconds>               no action; the next one comes that much later (at least A.MIN_WAIT, 0.01 s)
--
-- A bite fires a reaction (rules reaction.<venom>, model.reactions) when all of its conditions are up as the bite lands:
-- "Reactions fire on the bite command" (Venom.wiki:391). The bite of an impulse is a bite, so its suggestion can be one
-- of the conditions. A DSTAB fires no reaction. A venom that gives a random affliction (loki) is refused, except in a
-- bite whose venom has a reaction: then only the reaction is modelled, and the random affliction is not.

local A = {}

-- The shortest wait, and the shortest attacker gap (fight.lua F.gapDraw): a step shorter than this can round to now.
A.MIN_WAIT = 0.01

local KINDS = { dstab = true, flay = true, bite = true, impulse = true, give = true, wait = true }
-- The kinds that bite, and so can fire a reaction.
local BITES = { bite = true, impulse = true }
local FLAY_TARGETS = { shield = true, rebounding = true }

local function words(text)
  local out = {}
  for w in string.gmatch(text, "%S+") do out[#out + 1] = string.lower(w) end
  return out
end

--- Parse one action. Returns the action, or nil and the reason.
function A.parse(text, model)
  local w = words(text)
  local kind = w[1]
  if not kind or not KINDS[kind] then return nil, "unknown action '" .. tostring(text) .. "'" end
  local act = { kind = kind, text = table.concat(w, " "), venoms = {}, affs = {} }
  if kind == "wait" then
    act.seconds = tonumber(w[2])
    -- A wait under A.MIN_WAIT would set the next action at or before now (1.83 + 1e-17 is 1.83), and no later moment
    -- would run it. NaN and inf pass a "> 0" test in Lua 5.1, and they too stop the run (review ENG-5).
    local sec = act.seconds
    if not sec or sec ~= sec or sec < A.MIN_WAIT or sec == math.huge then
      return nil, "wait needs a number of seconds of at least " .. A.MIN_WAIT .. ": '" .. text .. "'"
    end
    return act
  end
  if kind == "give" then
    for i = 2, #w do act.affs[#act.affs + 1] = w[i] end
    if #act.affs == 0 then return nil, "give needs an affliction: '" .. text .. "'" end
    return act
  end
  local first = 2
  if kind == "flay" and FLAY_TARGETS[w[2] or ""] then
    act.target = w[2]
    first = 3
  end
  if kind == "impulse" then
    if #w ~= 3 then return nil, "impulse takes a suggestion and one venom: '" .. text .. "'" end
    -- An impulse gives a trivial suggestion only (Hypnosis.wiki:50). A word off that list is refused, as an unknown
    -- venom is: it would land as an affliction that no rule cures (review KE-5).
    local known = false
    for i = 1, #(model.suggestions or {}) do
      if model.suggestions[i] == w[2] then known = true end
    end
    if not known then
      return nil, "unknown suggestion '" .. w[2] .. "': an impulse gives a trivial suggestion only (rule"
        .. " attack.impulse.suggestions)"
    end
    act.suggestion = w[2]
    first = 3
  end
  for i = first, #w do
    local v = model.venoms[w[i]]
    if not v then return nil, "unknown venom '" .. w[i] .. "'" end
    if v.random and not (BITES[kind] and A.reaction(model, w[i])) then
      return nil, "venom '" .. w[i] .. "' gives a random affliction: not modelled"
    end
    act.venoms[#act.venoms + 1] = w[i]
  end
  local want = (kind == "dstab") and model.dstabVenoms or ((kind == "bite") and 1 or nil)
  if want and #act.venoms ~= want then
    return nil, string.format("%s takes %d venom(s), got %d: '%s'", kind, want, #act.venoms, text)
  end
  if kind == "flay" and #act.venoms > 1 then return nil, "flay takes at most one venom: '" .. text .. "'" end
  return act
end

function A.script(lines, model)
  local out = {}
  for i = 1, #lines do
    local act, why = A.parse(lines[i], model)
    if not act then return nil, why end
    out[#out + 1] = act
  end
  return out
end

-- The afflictions one venom gives that the victim does not have. They land at once. "a|b" means a, else b: the
-- package breaks the left limb first, and the right one when the left is broken or damaged (venom_to_aff,
-- 001_Miscellaneous_Aff_Tracking_Methods.lua:233-245; rules venom.epseth, venom.epteth).
local function damaged(part)
  return (string.gsub(part, "^broken", "damaged"))
end

local function envenom(s, name, model, landed)
  local v = model.venoms[name]
  for i = 1, #v.affs do
    local aff = v.affs[i]
    if string.find(aff, "|", 1, true) then
      local parts = {}
      for part in string.gmatch(aff, "[^|]+") do parts[#parts + 1] = part end
      local pick
      for k = 1, #parts do
        local last = k == #parts
        if not s.affs[parts[k]] and (last or not s.affs[damaged(parts[k])]) then
          pick = parts[k]
          break
        end
      end
      aff = pick
    end
    if aff and not s.affs[aff] then
      s.affs[aff] = true
      landed[#landed + 1] = aff
    end
  end
end

--- Slickness strips the sileris coating as it lands (rule defence.sileris.slickness: 8 of 8 in the logs, all from a
--- DSTAB, for example X 144-146: the second venom, "You have been afflicted with slickness.", then "The protective
--- covering coating your skin sloughs off."). A give and a FLAY's venom strip it the same way. Returns true when it
--- stripped the coating.
local function slick(s, landed)
  if not s.defs.sileris then return false end
  for i = 1, #landed do
    if landed[i] == "slickness" then
      s.defs.sileris = false
      return true
    end
  end
  return false
end

--- The reaction of a venom (model.reactions[venom]: { conditionals, gives }), or nil when the model has none.
function A.reaction(model, venom)
  return model.reactions and model.reactions[venom] or nil
end

-- A bite that reaches the victim. The reaction's conditions are read before the venom's own affliction lands ("the
-- afflictions which the subject must already labour under", Venom.wiki:391). Its afflictions land after the venom's.
-- Returns the venom when its reaction fired.
local function bite(s, name, model, landed, by)
  local r = A.reaction(model, name)
  local fired = r ~= nil and #r.conditionals > 0
  if r then
    for i = 1, #r.conditionals do
      if not s.affs[r.conditionals[i]] then fired = false end
    end
  end
  local before = #landed
  envenom(s, name, model, landed)
  for i = before + 1, #landed do by[landed[i]] = "bite" end
  if not fired then return nil end
  for i = 1, #r.gives do
    local aff = r.gives[i]
    if not s.affs[aff] then
      s.affs[aff] = true
      landed[#landed + 1] = aff
      by[aff] = "reaction"
    end
  end
  return name
end

--- Apply one action to the victim's state. Returns the result word, the afflictions that landed, whether the action
--- stripped the sileris coating (a FLAY, or slickness that landed), and for a bite or an impulse a table
--- { by = { affliction = "impulse" | "bite" | "reaction" }, reaction = the venom whose reaction fired, or nil }.
--- Result words: hit, shield (blocked), rebounded, flay.shield, flay.rebounding, flay.sileris, flay.missing (a named
--- FLAY whose defence was not there), flay, sileris (blocked).
function A.apply(s, act, model)
  local landed = {}
  if act.kind == "impulse" then
    local info = { by = {} }
    if s.defs.shield then return "shield", landed, false, info end
    -- The suggestion lands first: the impulse line comes before the bite line in its packet (FL 1269, 1273). No trivial
    -- suggestion is slickness, so the suggestion never strips the coating.
    if not s.affs[act.suggestion] then
      s.affs[act.suggestion] = true
      landed[1] = act.suggestion
      info.by[act.suggestion] = "impulse"
    end
    if s.defs.sileris then return "sileris", landed, false, info end
    info.reaction = bite(s, act.venoms[1], model, landed, info.by)
    return "hit", landed, false, info
  end
  if act.kind == "give" then
    for i = 1, #act.affs do
      if not s.affs[act.affs[i]] then
        s.affs[act.affs[i]] = true
        landed[#landed + 1] = act.affs[i]
      end
    end
    return "give", landed, slick(s, landed)
  end
  if act.kind == "dstab" then
    if s.defs.shield then return "shield", landed end
    if s.defs.rebounding then return "rebounded", landed end
    for i = 1, #act.venoms do envenom(s, act.venoms[i], model, landed) end
    return "hit", landed, slick(s, landed)
  end
  if act.kind == "bite" then
    -- A BITE lands only with the coating down, so its slickness strips nothing.
    local info = { by = {} }
    if s.defs.shield then return "shield", landed, false, info end
    if s.defs.sileris then return "sileris", landed, false, info end
    info.reaction = bite(s, act.venoms[1], model, landed, info.by)
    return "hit", landed, false, info
  end
  if act.kind == "flay" then
    local target = act.target
    if not target and model.flayOrder == "auto" then
      target = (s.defs.shield and "shield") or (s.defs.rebounding and "rebounding") or nil
    end
    local what, coat = "flay", false
    if target then
      -- A named FLAY strips its defence, and the coating with it (rule attack.flay.coating: 23 of 23 in the logs).
      if s.defs[target] then
        s.defs[target] = false
        what = "flay." .. target
        if s.defs.sileris then
          s.defs.sileris = false
          coat = true
        end
      else
        -- The named defence is not there. The FLAY strips the coating, as a bare FLAY does (rule attack.flay.missing:
        -- FL 305 "You try to flay a non-existent aura of rebounding", FL 308 the coating ripped). The alternative
        -- "nothing" strips nothing (the X 5328 reading).
        what = "flay.missing"
        if model.flayMissing ~= "nothing" and s.defs.sileris then
          s.defs.sileris = false
          coat = true
        end
      end
    elseif s.defs.sileris then
      s.defs.sileris = false
      what, coat = "flay.sileris", true
    end
    if act.venoms[1] and not s.defs.shield and not s.defs.rebounding then
      envenom(s, act.venoms[1], model, landed)
      -- A whip that lands slickness on the coating strips it too (review R5-engine-1). Only a named FLAY whose defence is
      -- not there, under the alternative "nothing" of rule attack.flay.missing, can whip with the coating up. No log
      -- shows slickness from such a whip.
      if not coat then coat = slick(s, landed) end
    end
    return what, landed, coat
  end
  return "wait", landed
end

--- The line names of tools/kb_events.py for an action's result, so one scorer reads a sim fight and a real log.
--- Returns the attack's name and the other lines of the same attack: { side, kind, name } each.
---   A DSTAB prints the prick, then its second-venom line (dstab.second, after hits and misses alike). A DSTAB or BITE
---   on a shield prints the block line (blocked.shield); a rebounded one prints the prick and then "The attack
---   rebounds back onto <name>!" (rebounded). Slickness that strips the coating prints its line sileris.down
---   (X 146). A FLAY prints what it stripped, the coating's line sileris.down when it went too (az rows 269-270), then
---   the whip line (flay.whip) when the venom can land.
---   An IMPULSE is the attack "bite" (kb_events' name for the victim's bite line, so the race counts it), with the
---   part "gaze.command" (kind hypnosis) for its suggestion: each of the 22 BITEs in the four victim-seat logs came in
---   the packet of "<name> fixes her gaze to yours and hisses a sharp command.", with the suggestion between (az
---   1238-1242: masochism, then the bite; Z5 534-537, X 293-296), so a sim fight's census counts it as a log's does.
---   The part follows the bite here; race() does not read a hypnosis line. A reaction that fires adds the engine's own
---   part "reaction", whose args name the venom (our seat prints "You sense the weakness in <name> as your <venom>
---   takes hold.").
function A.lines(act, result, s, coat, info)
  if act.kind == "dstab" or act.kind == "bite" or act.kind == "impulse" then
    if result == "shield" then return "blocked.shield", {} end
    local parts = {}
    if act.kind == "impulse" then parts[#parts + 1] = { side = "A", kind = "hypnosis", name = "gaze.command" } end
    if act.kind == "dstab" then parts[#parts + 1] = { side = "A", kind = "attack.part", name = "dstab.second" } end
    if result == "rebounded" then parts[#parts + 1] = { side = "A", kind = "attack.part", name = "rebounded" } end
    if coat then parts[#parts + 1] = { side = "V", kind = "defence", name = "sileris.down" } end
    if info and info.reaction then
      parts[#parts + 1] = { side = "A", kind = "attack.part", name = "reaction", args = { info.reaction } }
    end
    return (act.kind == "impulse") and "bite" or act.kind, parts
  end
  if act.kind == "flay" then
    local whip = not s.defs.shield and not s.defs.rebounding
    local parts = {}
    if coat then parts[#parts + 1] = { side = "V", kind = "defence", name = "sileris.down" } end
    if result == "flay.shield" or result == "flay.rebounding" then
      if whip then parts[#parts + 1] = { side = "A", kind = "attack", name = "flay.whip" } end
      return result, parts
    end
    -- A bare FLAY, and a named one whose defence was not there, print what a bare FLAY prints: the coating's line when
    -- it went, then the whip (FL 305-318 from our seat). No log shows a FLAY that strips nothing and cannot whip:
    -- "flay" is the engine's own name for it.
    return whip and "flay.whip" or "flay", parts
  end
  return act.kind, {}
end

return A
