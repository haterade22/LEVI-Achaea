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
    -- PRIORITY 2: Life-threatening / total incapacitation
    -----------------------------------------------------------
    ["aeon"] = 2,             -- Blocks everything. Smoke (elm).
    ["hypothermia"] = 2,      -- Ticking freeze kill. Salve.
    ["peace"] = 2,            -- Cannot attack or defend. Bellwort.

    -----------------------------------------------------------
    -- PRIORITY 3: Severe incapacitation / lock core
    -----------------------------------------------------------
    ["sleeping"] = 3,         -- Total incapacitation. Bal-free.
    ["slickness"] = 3,        -- Softlock core. Smoke (valerian). Higher than para so smoke > eat broot.
    ["pacified"] = 3,         -- Prevents aggressive actions. Bellwort.
    ["paralysis"] = 3,        -- Blocks tree (emergency escape). Bloodroot has NO herb competition. paraAst swap boosts to 1.

    -----------------------------------------------------------
    -- PRIORITY 3: Urgent damage / near-lock
    -----------------------------------------------------------
    ["scytherus"] = 3,        -- Ticking damage + relapse. Ginseng.
    ["heartseed"] = 3,        -- Ticking kill. Salve.

    -----------------------------------------------------------
    -- PRIORITY 4: Lock components / critical affs
    -----------------------------------------------------------
    ["anorexia"] = 4,         -- Blocks eating. Softlock core. Salve/focus.
    ["sandfever"] = 4,        -- Pariah mechanic. Goldenseal.
    ["impatience"] = 4,       -- Hardlock component. Blocks focus. #1 goldenseal priority.

    -----------------------------------------------------------
    -- PRIORITY 5: Important combat / balance-free
    -----------------------------------------------------------
    ["timeloop"] = 5,         -- DW mechanic. Bellwort.
    ["hypochondria"] = 5,     -- Aff amplifier. Kelp.
    ["crushedthroat"] = 5,    -- Eventually kills. Salve.
    ["itching"] = 5,          -- Forces scratching (lose bal). Salve.
    ["mycalium"] = 5,         -- Magi mechanic. Ginseng.
    ["flushings"] = 5,        -- Pariah mechanic. Ginseng.
    ["prone"] = 5,            -- Enables kill combos. Bal-free.
    ["fear"] = 5,             -- Forces fleeing. Bal-free.
    ["disrupted"] = 5,        -- Blocks tree tattoo. Bal-free.

    -----------------------------------------------------------
    -- PRIORITY 6: Writhe / moderate combat
    -----------------------------------------------------------
    ["bound"] = 6,            -- Writhe.
    ["transfixation"] = 6,    -- Writhe.
    ["webbed"] = 6,           -- Writhe.
    ["entangled"] = 6,        -- Writhe.
    ["daeggerimpale"] = 6,    -- Writhe.
    ["impaled"] = 6,          -- Writhe.
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
    ["unweavingbody"] = 7,    -- Psion mechanic.
    ["brokenrightleg"] = 7,   -- Mending.
    ["brokenleftleg"] = 7,    -- Mending.
    ["voyria"] = 7,           -- Sip-cured (separate balance). Class lock aff for Apostate. (was 9)

    -----------------------------------------------------------
    -- PRIORITY 8: Mental fallback / moderate
    -----------------------------------------------------------
    ["unweavingmind"] = 8,    -- Psion mechanic.
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
    ["darkshade"] = 9,        -- dShade swap handles urgent cases. Ginseng.
    ["hypersomnia"] = 9,      -- Ash.
    ["hallucinations"] = 9,   -- Ash.
    ["fratricide"] = 9,       -- fratLock swap boosts to 4 when approaching lock. Lobelia.
    ["crackedribs"] = 9,      -- Health elixir.
    ["dizziness"] = 9,        -- Vertigo synergy. Goldenseal. Focus handles normally. (was 23)
    ["vertigo"] = 9,          -- Dizziness+vertigo = falling. Lobelia. (was 16)
    ["healthleech"] = 9,      -- Ticking damage. Kelp. (was 14)
    ["addiction"] = 9,        -- Riftlock enabler. Ginseng. (was 11)
    ["mangledhead"] = 9,      -- Mending.

    -----------------------------------------------------------
    -- PRIORITY 10: Arm breaks / misc
    -----------------------------------------------------------
    ["brokenleftarm"] = 10,   -- Mending.
    ["brokenrightarm"] = 10,  -- Mending.
    ["torntendons"] = 10,     -- Health elixir.
    ["horror"] = 10,          -- Less urgent than recklessness/masochism. (was 8)
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
    ["pressure"] = 17,        -- Smoke.
    --["rebounding"] = 18,    -- (DEFENCE QUEUE SLOT 18) IMPORTANT: keep below pressure

    ["burning"] = 19,         -- Salve.
    ["stuttering"] = 19,      -- Salve.
    ["slashedthroat"] = 19,   -- Salve.
    ["laceratedthroat"] = 19, -- Salve.
    ["selarnia"] = 20,        -- Salve.

    ["blindness"] = 26,       -- Ignored by SSC (custom handling).
    ["deafness"] = 26,        -- Ignored by SSC (custom handling).
  }
end