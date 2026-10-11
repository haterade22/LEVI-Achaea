--[[mudlet
type: script
name: Default Curing Prios
hierarchy:
- Levi_Ataxia
- LEVI
- Ataxia
- Ataxia
- System-related
- Curing Stuff
- Priority-related
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

-- unnamed > For Levi > Levi_062424 > leviticus > LeviAtaxia > Ataxia-DownloadThis > Ataxia > System-related > Curing Stuff > Priority-related > Default Curing Prios

-- Sends all default curing priorities to SSC, staggered to avoid flooding.
-- Both resetOnLogin and resetPrios use the same table-driven approach.
function ataxia_sendDefaultPrios()
  -- `curing priority <aff> <n>` writes to whichever curingset is ACTIVE. If this ran
  -- while the PvE `bash` set were selected (reset prios, or a login landing mid-bash)
  -- it would overwrite that set with the PvP table and silently destroy it -- the
  -- profile would still "switch", just to a duplicate of normal. Leave the bash set
  -- first; ataxia_bashProfileOn re-arms on the next "basher enabled".
  if ataxia_bashProfileActive and ataxia_bashProfileActive() then
    if ataxia_bashProfileOff then ataxia_bashProfileOff() end
    if ataxiaEcho then
      ataxiaEcho("Left the bash curing set before resetting priorities -- re-enable the basher to switch back.")
    end
  end

  local prios = ataxia_defaultCuringPrios()
  -- Collect into array for deterministic batching
  local entries = {}
  for aff, val in pairs(prios) do
    entries[#entries + 1] = "curing priority " .. aff .. " " .. val
  end
  -- Sorted for the reason bashInstallWrite sorts: a retry must send the same thing. pairs()
  -- order is undefined, so the batching was non-deterministic. It also puts a family's BASE
  -- ahead of its overrides (" " sorts before "4"), which is the safe order to write them in.
  table.sort(entries)
  -- Send in batches of 5, staggered by 1.5s
  local batchSize = 5
  local delay = 0
  local sig = ataxia_prioTableSig(prios)
  for i = 1, #entries, batchSize do
    local batch = {}
    for j = i, math.min(i + batchSize - 1, #entries) do
      batch[#batch + 1] = entries[j]
    end
    local cmd = table.concat(batch, ";")
    local last = (i + batchSize > #entries)
    local function go()
      send(cmd)
      -- Record what the server now holds only once the LAST batch is out, so a disconnect
      -- halfway leaves the table marked unsent and the next login sends it again.
      if last then ataxia_prioMarkSent(sig) end
    end
    if delay == 0 then
      go()
    else
      tempTimer(delay, go)
    end
    delay = delay + 1.5
  end
end

-- KEEPING THE SERVER IN STEP WITH THIS TABLE (v4.7.397).
--
-- A capture of CURING PRIORITY LIST on 2026-10-10 showed the `normal` set still holding
-- JANUARY's values (broken arms 1 where this table says 10, legs 2 vs 7, weariness, horror,
-- crescendo, healthleech, scytherus...). This table is only sent by `reset prios`, and
-- ataxia_resetOnLogin has no caller, so every change made here since v4.7.276 (2026-08-19)
-- had never reached SSC. Editing this file did nothing until someone remembered to type a
-- command. Now a fingerprint of the table is stored when it is sent, and at login a changed
-- table is re-sent -- but ONLY into the `normal` set, confirmed by asking the game, because
-- a `curing priority` write lands in whichever set is active and must never overwrite a
-- class set or the PvE bash set. In any other set it says so instead of writing.

-- Order-independent fingerprint of a priority table.
function ataxia_prioTableSig(prios)
  prios = prios or ataxia_defaultCuringPrios()
  local parts = {}
  for k, v in pairs(prios) do parts[#parts + 1] = k .. "=" .. tostring(v) end
  table.sort(parts)
  return table.concat(parts, ",")
end

function ataxia_prioMarkSent(sig)
  ataxia.settings = ataxia.settings or {}
  ataxia.settings.prioSentSig = sig or ataxia_prioTableSig()
  if ataxia_saveSettings then pcall(ataxia_saveSettings, false) end
end

-- True when this table differs from what was last sent (or nothing has ever been recorded).
function ataxia_prioTableChanged()
  local sent = ataxia.settings and ataxia.settings.prioSentSig
  return sent ~= ataxia_prioTableSig()
end

-- What to do with a changed table, given the curingset the game says is active.
-- Pure, for the tests: "send", or a reason not to.
function ataxia_prioSyncDecide(changed, current)
  if not changed then return "unchanged" end
  if current == nil then return "unknown-set" end
  if current ~= "normal" then return "other-set" end
  return "send"
end

-- Called at login (login/001). Asks the game which set is active before writing anything.
function ataxia_prioSyncCheck()
  if not ataxia_prioTableChanged() then return end
  local function decide(parsed)
    local cur = parsed and parsed.current
    local what = ataxia_prioSyncDecide(true, cur)
    if what == "send" then
      if ataxiaEcho then
        ataxiaEcho("The curing priority table changed since it was last sent -- sending it to the <green>normal<reset> set now (about 40s).")
      end
      ataxia_sendDefaultPrios()
    elseif ataxiaEcho then
      ataxiaEcho("The curing priority table changed since it was last sent, but the active curing set is <yellow>"
        .. tostring(cur or "unknown") .. "<reset>. Switch to <green>normal<reset> and type <cyan>reset prios<reset> to apply it.")
    end
  end
  if ataxia_curingsetRefresh then
    ataxia_curingsetRefresh(decide)
  else
    decide(nil)
  end
end

function ataxia_resetOnLogin()
  ataxia.curingprio = ataxia.curingprio or {}
  ataxia_sendDefaultPrios()
end

function ataxia_resetPrios()
  ataxia_sendDefaultPrios()
end

function ataxia_defaultCuringPrios()
  return {
    -----------------------------------------------------------
    -- PRIORITY 1: RESERVED for on-the-fly emergency swaps
    -----------------------------------------------------------

    -----------------------------------------------------------
    -- PRIORITY 2: Life-threatening / total incapacitation / writhe / escape
    -----------------------------------------------------------
    ["aeon"] = 2,             -- Blocks everything. Smoke (elm).
    ["hypothermia"] = 2,      -- Ticking freeze kill. Salve.
    ["peace"] = 2,            -- Cannot attack or defend. Bellwort.
    ["sleeping"] = 2,         -- Total incapacitation. Bal-free.
    ["heartseed"] = 2,        -- Ticking kill. Salve.
    ["prone"] = 2,            -- Enables kill combos. Bal-free.
    ["disrupted"] = 2,        -- Blocks tree tattoo. Bal-free.
    ["voyria"] = 2,           -- Sip-cured (separate balance). Class lock aff.
    -- Writhe affs
    ["entangled"] = 2,        -- Writhe.
    ["bound"] = 2,            -- Writhe.
    ["daeggerimpale"] = 2,    -- Writhe.
    ["impaled"] = 2,          -- Writhe.
    ["transfixation"] = 2,    -- Writhe.
    ["webbed"] = 2,           -- Writhe.
    -- Psion unweaving lives in the STACKING AFFLICTIONS block at the foot of this table.

    -----------------------------------------------------------
    -- PRIORITY 3: Severe incapacitation / lock core
    -----------------------------------------------------------
    ["slickness"] = 3,        -- Softlock core. Smoke (valerian). Higher than para so smoke > eat broot.
    ["pacified"] = 3,         -- Prevents aggressive actions. Bellwort.
    ["paralysis"] = 3,        -- Blocks tree (emergency escape). Bloodroot has NO herb competition. paraAst swap boosts to 1.
    ["scytherus"] = 3,        -- Ticking damage + relapse. Ginseng.

    -----------------------------------------------------------
    -- PRIORITY 4: Lock components / critical affs
    -----------------------------------------------------------
    ["anorexia"] = 4,         -- Blocks eating. Softlock core. Salve/focus.
    ["sandfever"] = 4,        -- Pariah mechanic. Goldenseal.
    ["impatience"] = 4,       -- Hardlock component. Blocks focus. #1 goldenseal priority.
    ["timeloop"] = 4,         -- DW mechanic. Bellwort.

    -----------------------------------------------------------
    -- PRIORITY 5: Important combat / balance-free
    -----------------------------------------------------------
    ["hypochondria"] = 5,     -- Aff amplifier. Lobelia.
    ["crushedthroat"] = 5,    -- Eventually kills. Salve.
    ["itching"] = 5,          -- Forces scratching (lose bal). Salve.
    ["mycalium"] = 5,         -- Magi mechanic. Ginseng.
    ["flushings"] = 5,        -- Pariah mechanic. Ginseng.
    ["fear"] = 5,             -- Forces fleeing. Bal-free.

    -----------------------------------------------------------
    -- PRIORITY 6: Moderate combat
    -----------------------------------------------------------
    ["pyramides"] = 6,        -- Pariah mechanic. Salve.
    ["retribution"] = 6,
    ["depression"] = 6,       -- Goldenseal.
    ["shadowmadness"] = 6,

    -----------------------------------------------------------
    -- PRIORITY 7: Lock support / herb competition
    -----------------------------------------------------------
    -- weariness 7 -> 6 (v4.7.275). It was tied with three other kelp affs while its own comment
    -- already said "Blocks Fitness" -- and FITNESS is the whole lock-breaker
    -- (003_Lock_breakers: Blademaster/Druid/Infernal/Monk/Paladin/Runewarden/Sentinel/Serpent
    -- all gate on weariness). In the 2026-08-19 Grulk log weariness was up in 180 of 511 prompts
    -- and continuous for the last 19 seconds, so ataxia_canActive() was false through the entire
    -- true lock and the cure never went out. It got two kelp/aurum cures in 123 seconds.
    -- Curing weariness restores a REPEATABLE free asthma purge; curing asthma directly fixes one
    -- instance. Higher leverage, so it goes first.
    ["weariness"] = 6,        -- Blocks Fitness (the lock-breaker). Kelp. (was 7)
    ["asthma"] = 7,           -- Softlock core. #1 kelp priority. astWear swap boosts to 3 vs Serpent.
    ["sensitivity"] = 7,      -- Damage amplifier. Kelp.
    ["clumsiness"] = 7,       -- 33% miss chance! Kelp. (was 14)
    ["parasite"] = 7,         -- Kelp.
    ["rebbies"] = 7,          -- Pariah mechanic. Ginseng.
    ["brokenrightleg"] = 7,   -- Mending.
    ["brokenleftleg"] = 7,    -- Mending.

    -----------------------------------------------------------
    -- PRIORITY 8: Mental fallback / moderate
    -----------------------------------------------------------
    ["guilt"] = 8,            -- Paladin mechanic. Lobelia.
    ["nausea"] = 8,           -- Blocks parry. Ginseng. (was 11)
    ["skullfractures"] = 8,   -- Health elixir.
    ["stupidity"] = 8,        -- Focus handles normally; 8 is herb fallback. Goldenseal. (was 18)
    ["epilepsy"] = 8,         -- Seizures lose balance. Goldenseal. (was 18)
    ["recklessness"] = 8,     -- 50% more damage taken. Lobelia. Focus can cure. (was 21)
    ["masochism"] = 8,        -- Ekanelia enabler for Serpents. Lobelia. Focus can cure. (was 21)
    ["confusion"] = 8,        -- Blocks actions. Ash-cured (not goldenseal!). (was 20)
    ["damagedleftleg"] = 8,   -- Restoration.
    ["damagedrightleg"] = 8,  -- Restoration.
    ["mangledleftleg"] = 8,   -- Mending.
    ["mangledrightleg"] = 8,  -- Mending.

    -----------------------------------------------------------
    -- PRIORITY 9: Lower urgency
    -----------------------------------------------------------
    ["darkshade"] = 9,        -- darkshadeTracker auto-prioritizes after threshold. Ginseng.
    ["hypersomnia"] = 9,      -- Ash.
    ["hallucinations"] = 9,   -- Ash.
    ["fratricide"] = 25,      -- fratLock swap boosts to 4 when approaching lock. Lobelia. Deprioritized.
    ["crackedribs"] = 9,      -- Health elixir.
    ["dizziness"] = 9,        -- Vertigo synergy. Goldenseal. Focus handles normally. (was 23)
    ["vertigo"] = 9,          -- Dizziness+vertigo = falling. Lobelia. (was 16)
    -- healthleech moved to 8 -- see the PRIORITY 8 block below.
    ["addiction"] = 9,        -- Riftlock enabler. Ginseng. (was 11)
    ["mangledhead"] = 8,      -- Mending.

    -- healthleech 9 -> 8 (v4.7.275). Measured, not estimated: 12 unblockable ticks for 14,056
    -- damage in the 2026-08-19 Grulk log -- 16.5% of everything we took across 123 seconds --
    -- and it was never cured once, sitting at 9 behind a four-way kelp tie at 7. Per-tick value
    -- stepped 1,062 -> 1,390 (+31%) the moment SENSITIVITY landed, which is why sensitivity
    -- stays at 7 above it rather than being demoted alongside.
    ["healthleech"] = 8,      -- Ticking damage. Kelp. (was 9, was 14)

    -- damagedhead 12 -> 8 (v4.7.275). PvP deliberately ranks limbs low (see memory/curing.md),
    -- and this is a targeted exception, not a reversal: a BROKEN HEAD is what enables Sentinel
    -- Skirmishing's haft crush, which did 8,556 unblockable from 9,817 HP and ended the
    -- 2026-08-19 fight in one hit. Seven 14.7% throws is ~25 seconds of warning we did not use.
    -- Kept below the cure-channel blockers; moved above the arm restorations.
    ["damagedhead"] = 8,      -- Restoration. Head break = Skirmishing execute. (was 12)

    -----------------------------------------------------------
    -- PRIORITY 10: Arm breaks / misc
    -----------------------------------------------------------
    ["brokenleftarm"] = 10,   -- Mending.
    ["brokenrightarm"] = 10,  -- Mending.
    ["torntendons"] = 10,     -- Health elixir.
    ["paranoia"] = 10,        -- Blocks allies helping. Ash. (was 17)
    ["dementia"] = 10,        -- Random actions. Ash. (was 17)

    -----------------------------------------------------------
    -- PRIORITY 11: Low urgency combat
    -----------------------------------------------------------
    ["tenderskin"] = 11,      -- Lobelia.
    ["spiritburn"] = 11,      -- Lobelia.
    ["wristfractures"] = 11,  -- Health elixir.
    ["damagedleftarm"] = 11,  -- Restoration.
    ["lethargy"] = 11,        -- Ginseng.
    ["haemophilia"] = 11,     -- Ginseng.
    ["whisperingmadness"] = 11, -- Smoke.

    -----------------------------------------------------------
    -- PRIORITY 12: Low priority
    -----------------------------------------------------------
    -- damagedhead moved to 8 -- see the PRIORITY 8 block above.
    ["concussion"] = 12,      -- Health elixir.
    ["hellsight"] = 12,       -- Smoke.
    ["shyness"] = 12,         -- Focus handles it. Goldenseal. (was 23)

    -----------------------------------------------------------
    -- PRIORITY 13+: Situational / low impact
    -----------------------------------------------------------
    ["damagedrightarm"] = 13, -- Restoration.
    ["manaleech"] = 13,       -- Smoke.

    ["temperedmelancholic"] = 14,
    ["temperedcholeric"] = 14,
    ["temperedsanguine"] = 14,
    ["temperedphlegmatic"] = 14,
    ["lovers"] = 14,          -- Bellwort.
    ["deadening"] = 14,       -- Smoke.
    ["mangledleftarm"] = 14,  -- Mending.
    ["mangledrightarm"] = 14, -- Mending.
    ["dissonance"] = 14,      -- Goldenseal.

    ["frozen"] = 15,          -- Salve. Same rank as shivering.
    ["shivering"] = 15,       -- Salve. CALORIC at 15 unless vs Sentinel (move to 2).
    ["disloyalty"] = 15,      -- Smoke.

    ["scalded"] = 16,         -- Salve.
    ["loneliness"] = 16,      -- Lobelia.
    ["claustrophobia"] = 16,  -- Lobelia.
    ["agoraphobia"] = 16,     -- Lobelia.
    ["tension"] = 16,         -- Smoke.
    ["justice"] = 16,         -- Bellwort.
    ["generosity"] = 16,      -- Bellwort.

    ["serioustrauma"] = 17,   -- Salve.
    ["mildtrauma"] = 17,      -- Salve.
    ["pressure"] = 25,        -- Smoke. BASE for every stack count -- see the block below.
    --["rebounding"] = 18,    -- (DEFENCE QUEUE SLOT 18) IMPORTANT: keep below pressure

    ["stuttering"] = 19,      -- Salve.
    ["slashedthroat"] = 19,   -- Salve.
    ["laceratedthroat"] = 19, -- Salve.
    ["selarnia"] = 20,        -- Salve.

    ["stridulating"] = 24,    -- Deprioritized.
    ["indifference"] = 25,    -- Bellwort. Deprioritized.

    -----------------------------------------------------------
    -- STACKING AFFLICTIONS -- BASE + ESCALATION
    --
    -- Achaea changed the rules (announcement, 2026-08-19): a BARE `curing priority <aff> <n>`
    -- is the BASE for every stack count with no entry of its own, and `<aff><N> <n>` overrides
    -- it at exactly N stacks. The two used to conflict, which is the only reason these affs
    -- previously carried a value for EVERY level -- and why their bare entries (burning 19,
    -- pyre 8, horror 10) were unreachable: an explicit entry at every real count meant the
    -- base was never consulted.
    --
    -- READ A BASE AS "LEVEL 1". A bare name is what the server sends at one stack and is also
    -- what answers any count we did not anticipate, so the base carries the LOW value and the
    -- overrides escalate upward. (The inverse -- a dangerous base with low levels overridden
    -- down -- fails safe against an unexpected 6th stack, and is what to reach for if Achaea
    -- ever raises a cap.)
    --
    -- THE ESCALATION IS STATIC ON PURPOSE. Algedonic.AntiPaladin only runs once the target is
    -- KNOWN to be a Paladin, so a missed class read used to cost us the entire response. The
    -- table answers the same threat with no detection at all; the dynamic swap is left to
    -- handle only the emergency above it (priority 1, reserved).
    --
    -- A NEW NAME HERE IS UNVERIFIED UNTIL THE GAME ECHOES IT BACK. Nothing parses a REJECTED
    -- `curing priority` -- a bad affliction name fails in total silence. After editing:
    -- `reset prios`, wait, then CURING PRIORITY LIST (trigger 717 parses it into
    -- ataxia.curingprio) and confirm every name below came back at its value.
    --
    -- Stacking affs with a BARE ENTRY ONLY are correct as they stand and must not be
    -- "completed": pressure (25), crackedribs (9), torntendons (10), skullfractures (8),
    -- wristfractures (11) and the four tempered* (14) do not get more dangerous per stack,
    -- so one base covers every count. crescendo and unweavingspirit have NO entry at all and
    -- run on the server's own default -- a gap, recorded rather than silently priced.
    -----------------------------------------------------------
    -- CHECK THE CURE BALANCE BEFORE CHOOSING A NUMBER. These two families look alike and
    -- are not: BURNING is a SALVE (mending body -- 391_Applied_Body_Skin decrements it one
    -- stack per application) while PYRE is an EAT (bellwort/cuprum -- see the bellwort list
    -- in 007_Branching_State_Tracker, and "Cuprum flake" in paladin.md). The first cut of
    -- this block labelled both "Salve" and priced pyre3 at 2, which put an EAT above
    -- paralysis at 3 -- whose own comment three bands up reads "Bloodroot has NO herb
    -- competition". A priority is a claim on ONE balance, so it only means anything beside
    -- the other afflictions cured by that same balance.
    --
    -- Both families now stay clear of the bands that stop us acting outright. The dynamic
    -- layer (Algedonic.AntiPaladin) still promotes them to the reserved slot 1 when the head
    -- is broken, which is the only state in which either is lethal.
    ["burning"] = 9,          -- Salve (mending body). BASE = levels 1-3.
    ["burning4"] = 6,         -- One stack short of the Damnation burn route. (was 9)
    ["burning5"] = 4,         -- Broken head + burning 5 IS Damnation. (was 9)
    ["pyre"] = 9,             -- EAT (bellwort/cuprum). BASE = levels 1-2; resto is safe there.
    ["pyre3"] = 5,            -- Pyre 3 pins the burn floor at 3 -- cure before resto. (was 9)
    ["horror"] = 9,           -- FLAT: horror does not get worse per stack. (was 10 + five 9s)
    ["unweavingbody"] = 25,   -- Ginseng. BASE = levels 1-2, deliberately deprioritized.
    ["unweavingbody3"] = 2,   -- Psion. 3+ stacks = critical.
    ["unweavingbody4"] = 2,
    ["unweavingbody5"] = 2,   -- 5 stacks = near-kill.
    ["unweavingmind"] = 25,   -- Goldenseal. BASE = levels 1-2, deliberately deprioritized.
    ["unweavingmind3"] = 2,   -- Psion. 3+ stacks = critical.
    ["unweavingmind4"] = 2,
    ["unweavingmind5"] = 2,   -- 5 stacks = near-kill.
    -- SPIRIT was the missing third. psion.md names the kill as "any TWO unweaves at level
    -- 3+", so pricing body and mind while leaving spirit on the server default covered two
    -- of the three components -- and left the one cured on a DIFFERENT balance (smoke
    -- valerian, psion.md: "cures ONE level at a time") as the cheap way through.
    ["unweavingspirit"] = 25,  -- Smoke (valerian). BASE = levels 1-2.
    ["unweavingspirit3"] = 2,  -- Psion. 3+ stacks = critical.
    ["unweavingspirit4"] = 2,
    ["unweavingspirit5"] = 2,  -- 5 stacks = near-kill.
    -- crescendo had no entry either, so it ran on the server default while AntiBard was
    -- prioaffing it at 4+. Ash, so priced with its ash siblings (confusion 8, hypersomnia
    -- and hallucinations 9). No escalation: nothing documents a crescendo kill threshold.
    ["crescendo"] = 9,        -- Ash. Bard mechanic.

    -----------------------------------------------------------
    -- THE GAME'S OTHER CURABLE AFFLICTIONS (v4.7.402)
    -----------------------------------------------------------
    -- The full AFFLICTION LIST (203, kb/raw/live/affliction_list.txt) held 85 afflictions this
    -- table never named. 71 of them cannot be cured by SSC at all -- 60 wear off ("Cure(s): Time")
    -- and 11 have "no known cures" -- so a priority would do nothing and none is set. These 14 do
    -- have a cure. 11 keep the value the server already gave them (captured live 2026-10-10);
    -- naming them here puts them under the table's control (ataxia_prioSyncCheck re-sends a
    -- changed table), so a server default can no longer drift unseen. Cures and effects are the
    -- game's own words, from kb/afflictions/afflictions.json.
    ["latched"] = 2,          -- Sip health. The Water Lord drowning latch -- a KILL route. Server
                              -- had 1; 1 is reserved here for on-the-fly swaps, 2 is the lethal band.
    ["icebound"] = 2,         -- Writhe. "Restrictive on any actions ... including the use of curative
                              -- arts." With the other writhe binds at 2. Server had 1.
    ["calcifiedskull"] = 2,   -- Restoration head. Timed: if not cured, the head jumps a damage level.
    ["calcifiedtorso"] = 2,   -- Restoration body. Same mechanic, torso.
    ["grievouswounds"] = 3,   -- Apply health to torso. "Enough of them" kills.
    ["dazed"] = 5,            -- Smoke elm. Removes all resistance to hypnotism (Serpent).
    ["frostbite"] = 5,        -- Caloric. Next freeze strips insulation and hits harder.
    ["kkractlebrand"] = 5,    -- Sip health. Fire Lord brand: lowers fire resist, can be detonated.
    ["dazzled"] = 7,          -- Mending head (or 60s). HALVES damage resistance. NEW: had no priority.
    ["internalbleeding"] = 8, -- Restoration body. "Massive bleeding."
    ["earworm"] = 8,          -- Smoke elm.
    ["fulminated"] = 8,       -- Goldenseal. A successful focus then strikes you with paralysis.
    ["diminished"] = 12,      -- Bellwort.
    ["tonguetied"] = 18,      -- Restoration head. Its ONLY effect is blocking the stuttering cure (19),
                              -- so it sits just above stuttering. Server had 7, which took the head
                              -- restoration ahead of damaged/mangled head (8).

    ["blindness"] = 26,       -- Ignored by SSC (custom handling).
    ["deafness"] = 26,        -- Ignored by SSC (custom handling).
    ["insomnia"] = 26,        -- Ignored by SSC (custom handling).
  }
end