--[[mudlet
type: script
name: Kai And Kata
hierarchy:
- Levi_Ataxia
- LEVI
- Ataxia
- Ataxia
- Combat
- Offensive Things
- Monk
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

--[[
  KAI AND KATA -- the monk state every offense shares.

  One place for facts that were scattered literals, one of them wrong (Kai Surge, 31 in the code,
  45 on the wiki: kb/CONFLICTS.md #9):
    * what a kai ability costs, and whether this round can pay for it   ataxia_kaiCost / ataxia_kaiAfford
    * how much kai we have, and whether we know at all                   ataxia_kai
    * when a Shikudo form should be left, and its `skata` override       ataxia_KATA / ataxia_kataShouldLeave
    * whether a live chain has gone too long without a strike            ataxia_kataAtRisk
    * whether the last ASSESS puts our target at half health or less     ataxia_assessAtMostHalf

  Readers: tekura/002 (TK6 surge), the kaido aliases, and since v4.7.420 the Shikudo offenses:
  006 (zz/xx/sk), 007 (sr) and 011 (vv). Functions and tables only, except the send watcher at
  the end, so a test can load this file alone.

  Where the inputs come from:
    ataxia.vitals.kai        update_stuff/004, from the Kai charstat (assumed "Kai: N%"; no capture
                             yet); ataxiaTemp.kaiAt stamps it
    ataxia.vitals.kata       charstats "Kata: N"; the chain line (trigger 164) and the lapse line
                             (165); zeroed on a form change (monk/003 shikudo_checkForms)
    ataxiaTemp.kataAt        164: when the last chain line printed, i.e. the last strike
    ataxiaTemp.lastAssess*   698: the raw ASSESS numbers and whom they were for
]]

-- ---------------------------------------------------------------------------------------------
-- KAI
-- ---------------------------------------------------------------------------------------------

-- What each KAI ability costs. Kai is a percentage, 0-100 (the prompt shows "K:59%"), so these
-- are absolute. All from AB KAIDO (kb/raw/wiki/Kaido.wiki). Three were also MEASURED in Mystor's
-- logs and all three equal the wiki:
--   boost    11   K:12% -> K:1% around one boost              (LcJC-rJ5:546-575)
--   cripple  41   K:100% -> K:59%                             (LcJC-rJ5:2700-2728)
--   choke    10   K:95% -> 85% -> 75% -> 65%, three chokes     (FceAmb0o:6386-6447)
-- Surge is unmeasured: no log has one. 45 errs the safe way -- a skipped surge only waits, while
-- a refused one wastes the round it was meant to open.
ataxia_KAI_COST = {
  boost       = 11, -- Kaido.wiki:341
  choke       = 10, -- Kaido.wiki:286 (and 50 mana); free against a denizen, :289
  heal        = 21, -- Kaido.wiki:308
  cripple     = 41, -- Kaido.wiki:297
  surge       = 45, -- Kaido.wiki:319 (the code said 31: kb/CONFLICTS.md #9)
  enfeeble    = 61, -- Kaido.wiki:352
  deliverance = 81, -- Kaido.wiki:363
}

-- EQUILIBRIUM. The kai attacks that list a cost spend equilibrium (BOOST and DELIVERANCE list none)
-- -- choke 4.00 s (Kaido.wiki:288),
-- cripple 4.00 s (:299), surge 3.20 s (:321), enfeeble 3.00 s (:354), and heal 3.00 s (:310) -- so
-- a queued round carries at most one of them, and it competes with the MIND abilities for the
-- same equilibrium. BOOST lists no cooldown (:343) and went out in the same command as a combo
-- (LcJC-rJ5:561-565). No kai ability adds to the kata chain: [Rain]:3 before and after a cripple
-- (LcJC-rJ5:2700, :2728), [Willow]:3 through three chokes (FceAmb0o:6386-6447).

-- ataxia_kai() -> our kai (0-100), or nil when unknown.
-- Unknown until update_stuff/004 has read a charstats "Kai" THIS session, which it stamps in
-- ataxiaTemp.kaiAt. ataxia.vitals is saved wholesale and ataxiaTemp never is, so a kai restored
-- from disk -- a reading from another session -- has no stamp (the v4.7.299 rule). 004 also clears
-- vitals.kai on every tick, so a class without kai reads nil.
function ataxia_kai()
  if not (ataxiaTemp and ataxiaTemp.kaiAt) then return nil end
  return ataxia.vitals and tonumber(ataxia.vitals.kai) or nil
end

-- ataxia_kaiCost(ability, tgt) -> the kai `ability` costs against `tgt`; nil for an ability not
-- in ataxia_KAI_COST. `ability` is the word after KAI ("surge", "choke", ...), any case. `tgt` is
-- the target as the offense holds it; a NUMBER is a denizen (the basher's idiom), and nil or a
-- name is an adventurer. Two abilities are free against a denizen:
--   choke     "requires and consumes no kai energy when used against a denizen" (Kaido.wiki:289)
--   enfeeble  with the Spirit Rend boon (mnemSpiritRend): "Your kaido enfeeble ability costs no
--             kai and can target denizens" (basher/002, SPIRIT REND)
function ataxia_kaiCost(ability, tgt)
  if type(ability) ~= "string" then return nil end
  local a = ability:lower()
  local cost = ataxia_KAI_COST[a]
  if not cost then return nil end
  if type(tgt) == "number" then
    if a == "choke" then return 0 end
    if a == "enfeeble" and mnemSpiritRend then return 0 end
  end
  return cost
end

-- ataxia_kaiAfford(ability, spent, tgt) -> ok, have, need
--   need  ataxia_kaiCost(ability, tgt); nil for an unknown ability, which is never affordable.
--   have  the kai still free for this ability: ataxia_kai() minus `spent`; nil when kai is unknown.
--   ok    have >= need. A free ability (need 0) is always ok. Otherwise UNKNOWN kai is never ok:
--         a refused surge wastes its round, a skipped one only waits.
-- `spent` is kai already committed by earlier commands in the SAME queued round. The round is
-- built from one prompt's reading and fires all at once, so boost (11) then surge (45) needs 56,
-- not 45 (the one-spender rule, v4.7.193).
function ataxia_kaiAfford(ability, spent, tgt)
  local need = ataxia_kaiCost(ability, tgt)
  local kai = ataxia_kai()
  local have = kai and (kai - (tonumber(spent) or 0)) or nil
  if not need then return false, have, nil end
  if need == 0 then return true, have, 0 end
  if not have then return false, nil, need end
  return have >= need, have, need
end

-- ---------------------------------------------------------------------------------------------
-- KATA
-- ---------------------------------------------------------------------------------------------

-- When to leave a Shikudo form. The game has no maximum chain: the longer a chain runs in one form,
-- the likelier a STUMBLE, which resets the chain and drops you to Tykonos (Shikudo.wiki:116; Rain
-- allows "twice the normal length", :173; Tykonos is exempt, :116). No stumble appears in eight
-- logs (kb/CONFLICTS.md #8), so these numbers are POLICY taken from how the players fight, not
-- game limits:
--   min         a transition needs a kata of at least 5 (Shikudo.wiki:116). The refusal: attacker
--               log :961 (Willow, at a chain of 3, :960) and :1835 (Gaital).
--   leaveAfter  leave once the chain AFTER this round reaches it. Mystor never went past 12
--               outside Rain, and took Rain to 15 in 11 of 19 stints (16 at most).
--   lapseAfter  seconds without a strike before the chain may lapse: "You can no longer maintain
--               your deadly kata." (vNTjvghY:5967) -- still 12 about 17 s after the last strike,
--               gone by 19-20 s. The form is kept.
--   seenSafe    the longest chains seen WITHOUT a stumble (attacker log: Oak 13 at :1823, Rain 18
--               at :778). Only `skata` reads it, to warn when an override goes past it.
-- Only overrides are saved (ataxia.settings.shikudoKata[form], set by `skata`), so a release can
-- correct a default without a migration (deepMerge never deletes a saved key, v4.7.198).
ataxia_KATA = {
  min = 5,
  leaveAfter = { Willow = 12, Oak = 12, Gaital = 12, Maelstrom = 12, Rain = 15 },
  lapseAfter = 17,
  seenSafe = { default = 13, Rain = 18 },
}

local FORMS = { "Tykonos", "Willow", "Rain", "Oak", "Gaital", "Maelstrom" }

-- ataxia_shikudoForm(name) -> the form as charstats names it ("Rain"), from any case; nil for
-- anything else.
function ataxia_shikudoForm(name)
  if type(name) ~= "string" then return nil end
  local n = name:lower()
  for _, f in ipairs(FORMS) do
    if f:lower() == n then return f end
  end
  return nil
end

-- ataxia_kataLeaveAfter(form) -> the chain, counted after this round's strikes, at which `form` is
-- left: the `skata` override if one is saved, else ataxia_KATA.leaveAfter. Tykonos never stumbles,
-- so it leaves as soon as a transition is legal: always ataxia_KATA.min, never an override. nil for
-- an unknown form. Any case is accepted.
function ataxia_kataLeaveAfter(form)
  local f = ataxia_shikudoForm(form)
  if not f then return nil end
  if f == "Tykonos" then return ataxia_KATA.min end
  local saved = ataxia.settings and ataxia.settings.shikudoKata
  local n = type(saved) == "table" and tonumber(saved[f]) or nil
  return n or ataxia_KATA.leaveAfter[f]
end

-- ataxia_kataShouldLeave(form, kata, strikes) -> true when this round should transition.
--   kata     the chain now, before this round (ataxia.vitals.kata); nil reads as 0.
--   strikes  the strikes this round lands BEFORE the transition is judged. An INLINE
--            `combo ... transition <form>` is judged after its strikes (the chain line, then the
--            refusal: attacker :960-961), so pass the combo's count; pass 0 for a transition sent
--            before the combo.
-- Legal once the chain reaches ataxia_KATA.min; then it leaves at the form's cap (Tykonos: at
-- once). A refused transition costs nothing, the game keeps the chain (kb/CONFLICTS.md, resolved
-- 2026-10-11). False for an unknown form.
function ataxia_kataShouldLeave(form, kata, strikes)
  local cap = ataxia_kataLeaveAfter(form)
  if not cap then return false end
  local post = (tonumber(kata) or 0) + (tonumber(strikes) or 0)
  return post >= ataxia_KATA.min and post >= cap
end

-- ataxia_kataAtRisk(maxIdle) -> true when there is a chain to lose and its last strike (the last
-- chain line, ataxiaTemp.kataAt) is more than `maxIdle` seconds old (default
-- ataxia_KATA.lapseAfter). MIND and kai rounds add no kata, so a run of them must let a combo
-- through before the chain lapses. False when there is no chain: no chain line yet this session,
-- or the kata reads 0. The lapse line (165) and a form change (monk/003: a transition resets the
-- chain, Shikudo.wiki:116) zero the kata, but kataAt keeps the time of the strike whose chain is
-- gone -- a MIND round that carries a transition is a real pattern (vNTjvghY:715, :8444).
function ataxia_kataAtRisk(maxIdle)
  local at = ataxiaTemp and ataxiaTemp.kataAt
  if not at then return false end
  if (tonumber(ataxia.vitals and ataxia.vitals.kata) or 0) <= 0 then return false end
  return getEpoch() - at > (tonumber(maxIdle) or ataxia_KATA.lapseAfter)
end

-- ---------------------------------------------------------------------------------------------
-- ASSESS
-- ---------------------------------------------------------------------------------------------

-- ataxia_assessAtMostHalf(maxAge) -> true only when the last ASSESS (trigger 698) was of our
-- current target, is at most `maxAge` seconds old (default 5), and its RAW numbers show health at
-- half or less. Crescent kills a prone foe only "if that foe has half their health or less", and
-- otherwise is dodged with "greatly increased" recovery (Shikudo.wiki:358). ataxiaTemp.lastAssess
-- is floored, so 3540/7000 (50.57%) reads 50 and would pass. Names compare in any case, as
-- isTargeted does (016_Targeting_Functions).
function ataxia_assessAtMostHalf(maxAge)
  local t = ataxiaTemp
  if not t or not t.lastAssessAt then return false end
  if type(target) ~= "string" or type(t.lastAssessWho) ~= "string" then return false end
  if t.lastAssessWho:lower() ~= target:lower() then return false end
  if getEpoch() - t.lastAssessAt > (tonumber(maxAge) or 5) then return false end
  local hp, max = tonumber(t.lastAssessHp), tonumber(t.lastAssessMax)
  if not hp or not max or max <= 0 then return false end
  return hp * 2 <= max
end

-- ---------------------------------------------------------------------------------------------
-- skata -- show or override the kata caps (alias shikudo/006_Kata)
-- ---------------------------------------------------------------------------------------------

local function kataRow(f)
  local cap = ataxia_kataLeaveAfter(f)
  local note
  if f == "Tykonos" then
    note = "never stumbles: leaves as soon as legal"
  elseif cap ~= ataxia_KATA.leaveAfter[f] then
    note = "yours (default " .. ataxia_KATA.leaveAfter[f] .. ")"
  else
    note = "default"
  end
  return string.format("\n  <white>%-9s<reset> <cyan>%2s<reset>  %s", f, tostring(cap), note)
end

-- ataxia_kataCommand(formArg, valArg): the `skata` alias. `skata` shows every form's cap,
-- `skata <form>` one, `skata <form> <n>` saves an override (warning past seenSafe), and
-- `skata <form> default` drops it. Setting a form back to its default value drops it too, so the
-- saved table holds only real overrides.
function ataxia_kataCommand(formArg, valArg)
  if formArg == "" then formArg = nil end
  if valArg == "" then valArg = nil end
  -- Placeholders in capitals: cecho reads any <word> as a colour tag.
  local usage = "Usage: skata [FORM [N|default]] -- forms: " .. table.concat(FORMS, ", ") .. "."
  if not formArg then
    ataxiaEcho("Shikudo kata caps: a form is left once the chain AFTER the combo reaches its cap."
      .. " A transition needs a chain of " .. ataxia_KATA.min .. ".")
    local out = {}
    for _, f in ipairs(FORMS) do out[#out + 1] = kataRow(f) end
    cecho(table.concat(out)
      .. "\n  Longest chains seen without a stumble: " .. ataxia_KATA.seenSafe.default
      .. " (Rain " .. ataxia_KATA.seenSafe.Rain .. "). Change one: skata FORM N | skata FORM default")
    return
  end
  local f = ataxia_shikudoForm(formArg)
  if not f then return ataxiaEcho(usage) end
  if not valArg then return cecho(kataRow(f)) end
  if f == "Tykonos" then
    return ataxiaEcho("Tykonos never stumbles (Shikudo.wiki:116), so it leaves as soon as a transition"
      .. " is legal (" .. ataxia_KATA.min .. "). There is no cap to set.")
  end
  local def = ataxia_KATA.leaveAfter[f]
  local n = tonumber(valArg)
  if valArg:lower() ~= "default" and (not n or n ~= math.floor(n) or n < ataxia_KATA.min) then
    return ataxiaEcho(usage .. " The cap is a whole number of at least " .. ataxia_KATA.min .. ".")
  end
  ataxia.settings.shikudoKata = ataxia.settings.shikudoKata or {}
  if not n or n == def then
    ataxia.settings.shikudoKata[f] = nil
    ataxiaEcho("Shikudo kata: " .. f .. " leaves at <cyan>" .. def .. "<reset>, the default.")
  else
    ataxia.settings.shikudoKata[f] = n
    ataxiaEcho("Shikudo kata: " .. f .. " leaves at <cyan>" .. n .. "<reset> (default " .. def .. ").")
    local safe = ataxia_KATA.seenSafe[f] or ataxia_KATA.seenSafe.default
    if n > safe then
      ataxiaEcho("<red>[Shikudo] " .. f .. " " .. n .. " is past the longest chain seen without a stumble ("
        .. safe .. "). A stumble resets the chain and drops you to Tykonos.<reset>")
    end
  end
  if ataxia_saveSettings then ataxia_saveSettings(false) end
end

-- ---------------------------------------------------------------------------------------------
-- EVIDENCE FOR kb/CONFLICTS.md #8 (it changes no decision)
-- ---------------------------------------------------------------------------------------------

-- shikudo_checkForms (monk/003) reports a move into Tykonos that we did not ask for as a probable
-- STUMBLE. We ask for one with a form verb naming Tykonos -- TRANSITION (Shikudo.wiki:112), ADOPT
-- (:40), DISPATCH / INCAPACITATE with a form (:369) -- or with CRESCENT, after which "you shall
-- immediately flow into the Tykonos form" (:358). Only those stamp ataxiaTemp.shikFormSendAt: a
-- combo's inline `transition rain` does not, because a long chain carrying its transition is
-- exactly when a stumble is likeliest, and a stamp there would hide it. Whole words, so a target
-- named "Crescentia" stamps nothing.
local FORM_VERBS = { "transition", "adopt", "dispatch", "incapacitate" }

local function hasWord(s, w)
  return s:find("%f[%a]" .. w .. "%f[%A]") ~= nil
end

-- ataxia_shikFormSendSeen(cmd) -> true (and stamps ataxiaTemp.shikFormSendAt) when an outgoing
-- command can carry us into Tykonos on purpose.
function ataxia_shikFormSendSeen(cmd)
  if type(cmd) ~= "string" then return false end
  local c = cmd:lower()
  local into = hasWord(c, "crescent")
  if not into and hasWord(c, "tykonos") then
    for _, verb in ipairs(FORM_VERBS) do
      if hasWord(c, verb) then into = true; break end
    end
  end
  if not into then return false end
  ataxiaTemp = ataxiaTemp or {}
  ataxiaTemp.shikFormSendAt = getEpoch()
  return true
end

-- The watcher lives for the session. On a reload the old handler is killed first; its id is kept
-- on ataxiaTemp, never saved (a saved id would name a stranger's handler after a restart).
ataxiaTemp = ataxiaTemp or {}
if ataxiaTemp.shikFormSendHandler and killAnonymousEventHandler then
  pcall(killAnonymousEventHandler, ataxiaTemp.shikFormSendHandler)
end
ataxiaTemp.shikFormSendHandler = nil
if registerAnonymousEventHandler then
  ataxiaTemp.shikFormSendHandler = registerAnonymousEventHandler("sysDataSendRequest",
    function(_, cmd) ataxia_shikFormSendSeen(cmd) end)
end
