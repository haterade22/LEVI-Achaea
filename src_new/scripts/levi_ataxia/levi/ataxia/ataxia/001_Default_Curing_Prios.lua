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
  -- Send in batches of 5, staggered by 1.5s
  local batchSize = 5
  local delay = 0
  for i = 1, #entries, batchSize do
    local batch = {}
    for j = i, math.min(i + batchSize - 1, #entries) do
      batch[#batch + 1] = entries[j]
    end
    local cmd = table.concat(batch, ";")
    if delay == 0 then
      send(cmd)
    else
      local d = delay
      tempTimer(d, function() send(cmd) end)
    end
    delay = delay + 1.5
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
    -- Psion unweaving (high stacks = near-kill)
    ["unweavingbody5"] = 2,   -- Psion mechanic. 5 stacks = critical.
    ["unweavingbody4"] = 2,   -- Psion mechanic. 4 stacks.
    ["unweavingbody3"] = 2,   -- Psion mechanic. 3 stacks.
    ["unweavingmind5"] = 2,   -- Psion mechanic. 5 stacks = critical.
    ["unweavingmind4"] = 2,   -- Psion mechanic. 4 stacks.
    ["unweavingmind3"] = 2,   -- Psion mechanic. 3 stacks.

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
    ["asthma"] = 7,           -- Softlock core. #1 kelp priority. astWear swap boosts to 3 vs Serpent.
    ["sensitivity"] = 7,      -- Damage amplifier. Kelp.
    ["weariness"] = 7,        -- Blocks Fitness. Class lock aff. Kelp.
    ["clumsiness"] = 7,       -- 33% miss chance! Kelp. (was 14)
    ["parasite"] = 7,         -- Kelp.
    ["rebbies"] = 7,          -- Pariah mechanic. Ginseng.
    ["unweavingbody2"] = 25,  -- Psion mechanic (low stacks, deprioritized).
    ["unweavingbody1"] = 25,  -- Psion mechanic (low stacks, deprioritized).
    ["brokenrightleg"] = 7,   -- Mending.
    ["brokenleftleg"] = 7,    -- Mending.

    -----------------------------------------------------------
    -- PRIORITY 8: Mental fallback / moderate
    -----------------------------------------------------------
    ["unweavingmind2"] = 25,  -- Psion mechanic (low stacks, deprioritized).
    ["unweavingmind1"] = 25,  -- Psion mechanic (low stacks, deprioritized).
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
    ["healthleech"] = 9,      -- Ticking damage. Kelp. (was 14)
    ["addiction"] = 9,        -- Riftlock enabler. Ginseng. (was 11)
    ["mangledhead"] = 8,      -- Mending.

    -----------------------------------------------------------
    -- PRIORITY 10: Arm breaks / misc
    -----------------------------------------------------------
    ["brokenleftarm"] = 10,   -- Mending.
    ["brokenrightarm"] = 10,  -- Mending.
    ["torntendons"] = 10,     -- Health elixir.
    ["horror"] = 10,          -- Less urgent than recklessness/masochism. (was 8)
    ["horror1"] = 9,          -- Stacking horror.
    ["horror2"] = 9,          -- Stacking horror.
    ["horror3"] = 9,          -- Stacking horror.
    ["horror4"] = 9,          -- Stacking horror.
    ["horror5"] = 9,          -- Stacking horror.
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
    ["damagedhead"] = 12,     -- Restoration.
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
    ["pressure"] = 25,        -- Smoke. Deprioritized.
    --["rebounding"] = 18,    -- (DEFENCE QUEUE SLOT 18) IMPORTANT: keep below pressure

    ["burning"] = 19,         -- Salve.
    ["burning1"] = 9,         -- Salve. Stacking burn.
    ["burning2"] = 9,         -- Salve. Stacking burn.
    ["burning3"] = 9,         -- Salve. Stacking burn.
    ["burning4"] = 9,         -- Salve. Stacking burn.
    ["burning5"] = 9,         -- Salve. Stacking burn.
    ["pyre"] = 8,             -- Salve. Pyre damage.
    ["pyre1"] = 9,            -- Salve. Stacking pyre.
    ["pyre2"] = 9,            -- Salve. Stacking pyre.
    ["pyre3"] = 9,            -- Salve. Stacking pyre.
    ["stuttering"] = 19,      -- Salve.
    ["slashedthroat"] = 19,   -- Salve.
    ["laceratedthroat"] = 19, -- Salve.
    ["selarnia"] = 20,        -- Salve.

    ["stridulating"] = 24,    -- Deprioritized.
    ["indifference"] = 25,    -- Bellwort. Deprioritized.

    ["blindness"] = 26,       -- Ignored by SSC (custom handling).
    ["deafness"] = 26,        -- Ignored by SSC (custom handling).
    ["insomnia"] = 26,        -- Ignored by SSC (custom handling).
  }
end