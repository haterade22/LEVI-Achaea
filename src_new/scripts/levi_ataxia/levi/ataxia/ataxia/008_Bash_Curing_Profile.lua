--[[mudlet
type: script
name: Bash Curing Profile
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

-- PvE BASHING CURING PROFILE
--
-- ataxia_defaultCuringPrios() (001) is tuned entirely for PvP: the lock-core affs sit
-- at the top because a player is trying to stack asthma/anorexia/slickness/paralysis/
-- impatience on us. In PvE nothing is locking us, and that table answers a threat that
-- is not present using exactly the resources needed for the one that is.
--
-- The 2026-07-31 earth-wyrm death log made the cost measurable. Two facts drive
-- everything below:
--
--   1. POTASH/MOSS SHARES THE EATING BALANCE with every cure-mineral. Seven eats in the
--      final 13 seconds; exactly ONE was potash. Cuprum for paranoia (x3), plumbum for
--      shyness, argentum and calamine for other mental spray. "You may eat another bit
--      of irid moss or potash." printed at 07:45:36 and the next potash went down at
--      07:45:46 -- ten seconds of heal balance spent on afflictions that do nothing to
--      a basher, while HP fell 44% -> 25%.
--
--   2. MENDING AND RESTORATION SHARE THE SALVE BALANCE with crackedribs et al.
--      crackedribs is prio 9, brokenrightarm is 10, so at 07:45:43 the salve went to the
--      torso while `ra1` was still broken. Cracked ribs are a damage modifier; a broken
--      arm REFUSES the entire SnB attack -- four rounds were sent and refused outright
--      at 07:45:38-40 ("You cannot do that because both of your arms must be whole...").
--
-- So the PvE ordering is close to the inverse of the PvP one:
--   * limbs first  -- they gate our offence (arms) and every escape (legs);
--   * then whatever blocks a cure CHANNEL we depend on (anorexia -> eating -> potash;
--     slickness -> salves -> mending; paralysis -> tree);
--   * then the real damage math (recklessness, sensitivity, clumsiness, healthleech);
--   * salve competitors parked at 20 so they can never outbid a limb;
--   * the junk mental spray parked at 25 so it can never outbid a potash.
--
-- MECHANISM: a server-side curingset. `curing priority <aff> <n>` writes to whichever
-- set is ACTIVE, and Achaea stores priorities per set -- so the whole profile swap is
-- one `curingset switch`. Pushing ~55 priority commands through the 4/sec throttle in
-- 002 would take ~15 seconds each way, which is useless as a combat profile switch.
--
-- Because priority writes hit the ACTIVE set, anything that writes priorities while
-- `bash` is selected would silently corrupt it. ataxia_bashProfileActive() exists for
-- exactly that: ataxia_sendDefaultPrios, ataxia_setAffPrio/restorePrio, the Algedonic
-- swap layer and classDetect's own curingset switching all consult it. `curing prioaff`
-- is a TEMPORARY prioritisation and does not write stored priorities, so SLC's
-- defensive reactions are unaffected.

ataxia = ataxia or {}
ataxiaBashProfile = ataxiaBashProfile or {}  -- event-handler registry (reload-safe)

-- Priority at or above this is "parked": SSC will not spend a contested balance on it.
-- Guards elsewhere use this to tell a parked affliction from a real one -- notably the
-- Mnemosyne recovery hover, which only lands when we are affliction-free and would
-- otherwise float to its cap waiting on a paranoia nobody is curing.
ataxiaBashProfile.PARKED = 20

function ataxia_bashCuringSettings()
  ataxia.settings = ataxia.settings or {}
  ataxia.settings.bashcuring = ataxia.settings.bashcuring or {}
  local s = ataxia.settings.bashcuring
  if s.enabled == nil then s.enabled = true end
  if s.installed == nil then s.installed = false end
  s.setname = s.setname or "bash"
  s.restoreTo = s.restoreTo or "normal"
  return s
end

-- DELTA table -- only affs whose PvE priority differs from ataxia_defaultCuringPrios().
-- Install clones the PvP set first, so anything absent here keeps its PvP value.
-- Every key must exist in the default table and no value may equal the default: a no-op
-- delta is a mistake, not a decision. Both are asserted in test_bash_curing_profile.lua.
function ataxia_bashCuringPrios()
  return {
    -----------------------------------------------------------
    -- 2-3: blocks a cure CHANNEL we depend on
    -----------------------------------------------------------
    ["paralysis"] = 2,        -- (3) Blocks tree, the main PvE heal. Also parks the basher in dangerLevel "wait".
    ["anorexia"] = 3,         -- (4) Blocks eating -> blocks potash/moss -> blocks our health.
    -- slickness stays at 3: it blocks salves, i.e. it blocks mending. Already correct.

    -----------------------------------------------------------
    -- 4-6: LIMBS. Arms gate every weapon attack AND rifting; legs gate stand,
    -- tumble, leap, fly -- i.e. every rung of the escape ladder. Kept SYMMETRIC:
    -- the PvP table has damagedleftarm at 11 and damagedrightarm at 13 for no
    -- reason, and restoration always heals the LEFT limb of a pair first.
    -----------------------------------------------------------
    ["brokenleftarm"] = 4,    -- (10) Mending.
    ["brokenrightarm"] = 4,   -- (10) Mending.
    ["brokenleftleg"] = 4,    -- (7)  Mending.
    ["brokenrightleg"] = 4,   -- (7)  Mending.
    ["damagedleftarm"] = 5,   -- (11) Restoration.
    ["damagedrightarm"] = 5,  -- (13) Restoration.
    ["damagedleftleg"] = 5,   -- (8)  Restoration.
    ["damagedrightleg"] = 5,  -- (8)  Restoration.
    ["mangledleftarm"] = 5,   -- (14) Mending.
    ["mangledrightarm"] = 5,  -- (14) Mending.
    ["mangledleftleg"] = 5,   -- (8)  Mending.
    ["mangledrightleg"] = 5,  -- (8)  Mending.
    ["damagedhead"] = 6,      -- (12) Restoration.
    ["mangledhead"] = 6,      -- (8)  Mending.

    -----------------------------------------------------------
    -- 6: the real PvE damage math -- these change how fast we die
    -----------------------------------------------------------
    ["recklessness"] = 6,     -- (8) +50% damage taken.
    ["sensitivity"] = 6,      -- (7) Damage amplifier.
    ["hypochondria"] = 6,     -- (5) Affliction amplifier.
    ["clumsiness"] = 6,       -- (7) 33% miss chance -- straight DPS loss.
    ["healthleech"] = 6,      -- (9) Ticking damage.

    -----------------------------------------------------------
    -- 12: still cured, but never ahead of a limb
    -----------------------------------------------------------
    ["confusion"] = 12,       -- (8) Costs the odd round; not worth a mineral mid-swarm.

    -----------------------------------------------------------
    -- 20: SALVE COMPETITORS. Every one of these is a mending/restoration NOT
    -- applied to a limb. This band is the direct fix for the 07:45:43 cracked-ribs
    -- application that beat a broken right arm.
    -----------------------------------------------------------
    ["crackedribs"] = 20,     -- (9)
    ["skullfractures"] = 20,  -- (8)
    ["torntendons"] = 20,     -- (10)
    ["wristfractures"] = 20,  -- (11)
    ["concussion"] = 20,      -- (12)
    ["mildtrauma"] = 20,      -- (17)
    ["serioustrauma"] = 20,   -- (17)
    ["scalded"] = 20,         -- (16)

    -----------------------------------------------------------
    -- 25: THE MINERAL-BALANCE THIEVES. This is the earth wyrm's actual kit, and
    -- the reason the log shows one potash to six junk cures. None of these affect
    -- a basher; every one of them costs a heal.
    -----------------------------------------------------------
    ["paranoia"] = 25,        -- (10) cuprum x3 in the death log
    ["shyness"] = 25,         -- (12) plumbum
    ["depression"] = 25,      -- (6)
    ["masochism"] = 25,       -- (8)
    ["claustrophobia"] = 25,  -- (16)
    ["agoraphobia"] = 25,     -- (16)
    ["loneliness"] = 25,      -- (16)
    ["dementia"] = 25,        -- (10)
    ["hallucinations"] = 25,  -- (9)
    ["hypersomnia"] = 25,     -- (9)
    ["stupidity"] = 25,       -- (8)
    ["dizziness"] = 25,       -- (9)
    ["vertigo"] = 25,         -- (9)
    ["lethargy"] = 25,        -- (11)
    ["addiction"] = 25,       -- (9)
    ["tenderskin"] = 25,      -- (11)
    ["spiritburn"] = 25,      -- (11)
    ["hellsight"] = 25,       -- (12)
    ["manaleech"] = 25,       -- (13)
    ["deadening"] = 25,       -- (14)
    ["disloyalty"] = 25,      -- (15)
    ["tension"] = 25,         -- (16)
    ["whisperingmadness"] = 25, -- (11)
    ["dissonance"] = 25,      -- (14)
    ["generosity"] = 25,      -- (16)
    ["justice"] = 25,         -- (16)
    ["lovers"] = 25,          -- (14)
    ["shadowmadness"] = 25,   -- (6)
    ["retribution"] = 25,     -- (6)
    ["horror"] = 25,          -- (10)
    ["horror1"] = 25,         -- (9)
    ["horror2"] = 25,         -- (9)
    ["horror3"] = 25,         -- (9)
    ["horror4"] = 25,         -- (9)
    ["horror5"] = 25,         -- (9)
    ["temperedmelancholic"] = 25, -- (14)
    ["temperedcholeric"] = 25,    -- (14)
    ["temperedsanguine"] = 25,    -- (14)
    ["temperedphlegmatic"] = 25,  -- (14)

    -----------------------------------------------------------
    -- DELIBERATELY UNCHANGED (recorded so a future reader does not "fix" them):
    --   aeon, prone, sleeping, disrupted, hypothermia, heartseed, voyria, peace and
    --     the whole writhe band -- they stop us acting at all;
    --   slickness (3) -- blocks salves, i.e. blocks mending;
    --   asthma, weariness -- the Seasone phial truelock in Mnemosyne is asthma +
    --     anorexia, and the counter in mnemosyne/004 re-touches tree only while both
    --     persist; demoting asthma would lengthen that lock;
    --   nausea -- blocks parry, and the SLC bashing parry mode depends on it;
    --   epilepsy -- seizures lose balance;
    --   burning*/pyre*/scytherus/crushedthroat/itching/fear -- ticking damage or
    --     forced actions;
    --   guilt -- gotAff() sends `curing focus off` for it;
    --   blindness/deafness/insomnia (26) -- SSC-ignored by design, kept as defences.
    -----------------------------------------------------------
  }
end

function ataxia_bashProfileActive()
  local s = ataxia.settings and ataxia.settings.bashcuring
  return (s and s.active) == true
end

-- Which curingset are we on right now, as far as anything in this package knows?
-- classDetect owns the only other switcher, so its tracked value is the best source.
local function currentSet()
  local cd = classDetect and classDetect.state and classDetect.state.currentCuringset
  if type(cd) == "string" and cd ~= "" then return cd end
  local s = ataxia_bashCuringSettings()
  return s.restoreTo or "normal"
end

-- One-time server-side setup. Clones the PvP set so unlisted affs keep their values,
-- then writes only the deltas. Batched 5-per-command and staggered like
-- ataxia_sendDefaultPrios (001) -- the server rejects more than 5 commands a second.
-- The switch BACK is scheduled after the last batch: a priority written after we have
-- already left the set would land in the wrong one.
function ataxia_bashProfileInstall()
  local s = ataxia_bashCuringSettings()
  local from = currentSet()
  s.restoreTo = from

  local entries = {}
  for aff, val in pairs(ataxia_bashCuringPrios()) do
    entries[#entries + 1] = "curing priority " .. aff .. " " .. val
  end
  table.sort(entries)  -- deterministic batching, so a retry sends the same thing

  send("curingset new " .. s.setname)
  send("curingset switch " .. s.setname)
  send("curingset clone " .. from)

  local delay = 1.5
  for i = 1, #entries, 5 do
    local batch = {}
    for j = i, math.min(i + 4, #entries) do batch[#batch + 1] = entries[j] end
    local cmd = table.concat(batch, ";")
    tempTimer(delay, function() send(cmd) end)
    delay = delay + 1.5
  end

  tempTimer(delay, function()
    send("curingset switch " .. from)
    s.installed = true
    s.active = false
    if ataxiaEcho then
      ataxiaEcho("Bash curing profile '" .. s.setname .. "' installed (" .. #entries ..
        " priorities, cloned from '" .. from .. "'). Auto-switching is " ..
        (s.enabled and "ON" or "OFF") .. ".")
    end
    if ataxia_saveSettings then ataxia_saveSettings() end
  end)

  if ataxiaEcho then
    ataxiaEcho("Installing bash curing profile -- takes about " .. math.ceil(delay) .. "s. Do not bash until it finishes.")
  end
end

function ataxia_bashProfileOn()
  local s = ataxia_bashCuringSettings()
  if not s.enabled or not s.installed then return end
  if s.active then return end
  -- Remember where we came from BEFORE switching, or the restore goes to a stale set.
  s.restoreTo = currentSet()
  if s.restoreTo == s.setname then s.restoreTo = "normal" end
  s.active = true
  send("curingset switch " .. s.setname)
  if ataxiaEcho then ataxiaEcho("Curing -> <green>" .. s.setname .. "<reset> (PvE: limbs first, mental spray parked).") end
end

function ataxia_bashProfileOff()
  local s = ataxia_bashCuringSettings()
  if not s.active then return end
  s.active = false
  send("curingset switch " .. (s.restoreTo or "normal"))
  if ataxiaEcho then ataxiaEcho("Curing -> <green>" .. (s.restoreTo or "normal") .. "<reset> (PvP priorities restored).") end
end

function ataxia_bashProfileStatus()
  local s = ataxia_bashCuringSettings()
  if not ataxiaEcho then return end
  ataxiaEcho("Bash curing profile:")
  cecho("\n  <NavajoWhite>set name:   <white>" .. s.setname)
  cecho("\n  <NavajoWhite>installed:  " .. (s.installed and "<green>yes" or "<red>no  <DimGrey>(run: aconfig bashcuring install)"))
  cecho("\n  <NavajoWhite>auto-swap:  " .. (s.enabled and "<green>on" or "<red>off"))
  cecho("\n  <NavajoWhite>active now: " .. (s.active and "<green>yes" or "<DimGrey>no"))
  cecho("\n  <NavajoWhite>restore to: <white>" .. tostring(s.restoreTo) .. "\n")
end

function ataxia_bashProfileShow()
  local deltas = ataxia_bashCuringPrios()
  local defaults = ataxia_defaultCuringPrios and ataxia_defaultCuringPrios() or {}
  local rows = {}
  for aff, val in pairs(deltas) do rows[#rows + 1] = {aff = aff, bash = val, pvp = defaults[aff]} end
  table.sort(rows, function(a, b)
    if a.bash ~= b.bash then return a.bash < b.bash end
    return a.aff < b.aff
  end)
  if not ataxiaEcho then return end
  ataxiaEcho("Bash curing deltas (" .. #rows .. " afflictions) -- <DimGrey>pvp <white>-> <green>bash<reset>:")
  for _, r in ipairs(rows) do
    cecho("\n  <NavajoWhite>" .. r.aff .. string.rep(" ", math.max(1, 22 - #r.aff)) ..
      "<DimGrey>" .. tostring(r.pvp) .. " <white>-> " ..
      (r.bash >= ataxiaBashProfile.PARKED and "<red>" or "<green>") .. r.bash)
  end
  cecho("\n")
end

function ataxia_bashProfileToggle(onoff)
  local s = ataxia_bashCuringSettings()
  s.enabled = (onoff == "on")
  if not s.enabled and s.active then ataxia_bashProfileOff() end
  if ataxiaEcho then
    ataxiaEcho("Bash curing auto-switching " .. (s.enabled and "<green>ON" or "<red>OFF") .. "<reset>.")
  end
  if ataxia_saveSettings then ataxia_saveSettings() end
end

-- Registered at FILE LOAD with kill-before-register: a SYSUPDATE reload does not
-- re-run levilogin(), and a stacked handler would send the switch twice.
local function _reg(event, fnName)
  if ataxiaBashProfile[event] then pcall(killAnonymousEventHandler, ataxiaBashProfile[event]) end
  ataxiaBashProfile[event] = registerAnonymousEventHandler(event, fnName)
end
_reg("basher enabled", "ataxia_bashProfileOn")
_reg("basher disabled", "ataxia_bashProfileOff")
