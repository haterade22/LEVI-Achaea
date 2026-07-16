--[[mudlet
type: script
name: Setup Wizard
hierarchy:
- Levi_Ataxia
- Misc Scripts
attributes:
  isActive: 'yes'
  isFolder: 'no'
]]--

---------------------------------------------------------------------------
-- Ataxia Setup Wizard
-- Provides "ataxia setup" command for guided system configuration.
-- All settings are persisted via ataxia_saveSettings().
---------------------------------------------------------------------------

leviSetup = leviSetup or {}

-- ── colour shortcuts ────────────────────────────────────────────────────
local H  = "<dark_orchid>"       -- header / divider
local HL = "<light_slate_blue>"  -- highlight / label
local V  = "<NavajoWhite>"       -- value text
local G  = "<green>"             -- enabled / good
local R  = "<red>"               -- disabled / bad
local W  = "<white>"             -- white
local D  = "<dim_grey>"          -- dim / hint

-- ── helpers ─────────────────────────────────────────────────────────────
local function header(title)
  local bar = string.rep(utf8.char(9472), 50)
  cecho("\n" .. H .. bar)
  cecho("\n" .. HL .. "  " .. title)
  cecho("\n" .. H .. bar .. "\n")
end

local function row(label, value, hint)
  local pad = string.rep(" ", math.max(1, 22 - #label))
  cecho("\n  " .. V .. label .. pad .. W .. tostring(value or "nil"))
  if hint then cecho("  " .. D .. "(" .. hint .. ")") end
end

local function boolStr(val)
  if val then return G .. "ON" else return R .. "OFF" end
end

local function save()
  ataxia_saveSettings(false)
end

local function hint(text)
  cecho("\n  " .. D .. text)
end

-- ── dispatch ────────────────────────────────────────────────────────────
function leviSetup.dispatch(args)
  args = (args or ""):match("^%s*(.-)%s*$")  -- trim

  local cmd = args:match("^(%S+)")
  local rest = args:match("^%S+%s+(.+)$") or ""

  if not cmd or cmd == "" then
    leviSetup.showMenu()
  elseif cmd == "class"      then leviSetup.setupClass(rest)
  elseif cmd == "separator" or cmd == "sep" then leviSetup.setupSeparator(rest)
  elseif cmd == "weapons"    then leviSetup.setupWeapons(rest)
  elseif cmd == "basher"     then leviSetup.setupBasher(rest)
  elseif cmd == "sipping" or cmd == "sip" then leviSetup.setupSipping(rest)
  elseif cmd == "tracking"   then leviSetup.setupTracking(rest)
  elseif cmd == "gui"        then leviSetup.setupGui(rest)
  elseif cmd == "ndb"        then leviSetup.setupNdb(rest)
  elseif cmd == "combat"     then leviSetup.setupCombat(rest)
  elseif cmd == "slc"        then leviSetup.setupSlc(rest)
  elseif cmd == "mount"      then leviSetup.setupMount(rest)
  elseif cmd == "artefacts" or cmd == "arties" then leviSetup.setupArtefacts(rest)
  elseif cmd == "earrings"   then leviSetup.setupEarrings(rest)
  elseif cmd == "status"     then leviSetup.showStatus()
  elseif cmd == "install"    then leviSetup.setupInstall(rest)
  elseif cmd == "guide"      then leviSetup.setupGuide(rest)
  elseif cmd == "reporting" or cmd == "report" then leviSetup.setupReporting(rest)
  else
    ataxiaEcho("Unknown setup command: " .. W .. cmd)
    cecho("\n  " .. V .. "Type " .. HL .. "ataxia setup" .. V .. " for a list of commands.")
  end
end

-- ═══════════════════════════════════════════════════════════════════════
-- MAIN MENU
-- ═══════════════════════════════════════════════════════════════════════
function leviSetup.showMenu()
  header("Ataxia Setup Wizard")
  cecho("\n  " .. V .. "Configure your system with these commands:\n")

  local cmds = {
    {"ataxia setup class",     "Set your class (auto-detects from GMCP)"},
    {"ataxia setup separator", "Set command separator (currently: " .. (ataxia.settings.separator or ";") .. ")"},
    {"ataxia setup weapons",   "Configure weapon IDs (scan, set, confirm)"},
    {"ataxia setup mount",     "Set your mount/companion name"},
    {"ataxia setup artefacts", "Configure artefact IDs (pendant, belt, etc.)"},
    {"ataxia setup earrings",  "Configure travel earring locations"},
    {"ataxia setup basher",    "Basher settings (flee, gold pack, etc.)"},
    {"ataxia setup sipping",   "Health/mana sip thresholds"},
    {"ataxia setup tracking",  "Affliction tracking system (V1/V2)"},
    {"ataxia setup combat",    "Combat toggles (partyrelay, looting, etc.)"},
    {"ataxia setup slc",       "Self Limb Counter (parry, shield, alerts, etc.)"},
    {"ataxia setup gui",       "Toggle the GUI on/off"},
    {"ataxia setup ndb",       "Name Database highlighting colours"},
    {"ataxia setup install",   "First-time install (atinstall, abinstall, aninstall)"},
    {"ataxia setup guide",     "Post-install config guide (ataxia, basher, ndb)"},
    {"ataxia setup reporting", "Mnemosyne run tracker (token, auto on/off)"},
    {"ataxia setup status",    "Show all current settings at a glance"},
  }

  for _, c in ipairs(cmds) do
    cecho("\n  " .. HL .. c[1])
    local pad = string.rep(" ", math.max(1, 24 - #c[1]))
    cecho(pad .. D .. c[2])
  end

  hint("\n  Settings auto-save on disconnect. Manual save: ataxia setup save")
  cecho("\n")
end

-- ═══════════════════════════════════════════════════════════════════════
-- MNEMOSYNE RUN TRACKER
-- ═══════════════════════════════════════════════════════════════════════
function leviSetup.setupReporting(rest)
  -- Always operate on the persistent config table so token/toggle edits save.
  ataxia.settings = ataxia.settings or {}
  ataxia.settings.reporting = ataxia.settings.reporting
    or { enabled = false, contemplate = true, url = "http://104.128.56.238:8000" }
  local c = ataxia.settings.reporting
  local sub = (rest:match("^(%S+)") or ""):lower()
  local val = rest:match("^%S+%s+(.+)$") or ""

  if sub == "token" then
    if val == "" then
      ataxiaEcho("Usage: ataxia setup reporting token <token>")
    else
      c.token = val
      save()
      ataxiaEcho("Mnemosyne token saved.")
    end
    return
  elseif sub == "on" then
    c.enabled = true; save(); ataxiaEcho("Mnemosyne auto-reporting ON.")
    return
  elseif sub == "off" then
    c.enabled = false; save(); ataxiaEcho("Mnemosyne auto-reporting OFF.")
    return
  elseif sub == "test" then
    if ataxia.mnemosyne then ataxia.mnemosyne.testHealth() end
    return
  end

  header("Mnemosyne Run Tracker")
  row("Server", c.url or "-")
  row("Token", c.token and "set" or "not set")
  row("Auto reporting", boolStr(c.enabled))
  row("Auto-contemplate", boolStr(c.contemplate))
  cecho("\n")
  hint("ataxia setup reporting token <token>   Save your API token")
  hint("ataxia setup reporting on | off        Toggle automatic reporting")
  hint("ataxia setup reporting test            Ping the server (/health)")
  hint("Or use the mnem alias: mnem token <t>, mnem on, mnem status, mnem test")
  cecho("\n")
end

-- ═══════════════════════════════════════════════════════════════════════
-- CLASS SETUP
-- ═══════════════════════════════════════════════════════════════════════
function leviSetup.setupClass(rest)
  local detected = (gmcp and gmcp.Char and gmcp.Char.Status and gmcp.Char.Status.class)
                   or (ataxiaTemp and ataxiaTemp.class) or nil

  if rest and rest ~= "" then
    ataxia.settings.class = rest
    if ataxiaTemp then ataxiaTemp.class = rest end
    save()
    ataxiaEcho("Class set to: " .. W .. rest)
    return
  end

  header("Class Setup")

  row("Current class", ataxia.settings.class or "Unknown")
  if detected then
    row("GMCP detected", detected)
  end

  local classes = {
    "Alchemist", "Apostate", "Bard", "Blademaster", "Depthswalker",
    "Druid", "Infernal", "Jester", "Magi", "Monk", "Occultist",
    "Paladin", "Pariah", "Priest", "Psion", "Runewarden", "Sentinel",
    "Serpent", "Shaman", "Sylvan", "Unnamable",
    "Airlord", "Earthlord", "Firelord", "Waterlord", "Dragon",
  }

  cecho("\n\n  " .. V .. "To set your class:")
  cecho("\n  " .. HL .. "ataxia setup class <ClassName>")
  hint("  e.g.: ataxia setup class Infernal")

  if detected and detected ~= "Unknown" and detected ~= (ataxia.settings.class or "") then
    cecho("\n\n  " .. G .. "GMCP detected " .. W .. detected .. G .. ". To accept:")
    cecho("\n  " .. HL .. "ataxia setup class " .. detected)
  end

  cecho("\n\n  " .. D .. "Available: " .. table.concat(classes, ", "))
  cecho("\n")
end

-- ═══════════════════════════════════════════════════════════════════════
-- SEPARATOR
-- ═══════════════════════════════════════════════════════════════════════
function leviSetup.setupSeparator(rest)
  if rest and rest ~= "" then
    ataxia.settings.separator = rest
    save()
    ataxiaEcho("Separator set to: " .. W .. rest)
    return
  end

  header("Command Separator")
  row("Current separator", ataxia.settings.separator or ";")

  cecho("\n\n  " .. V .. "The separator joins multiple commands in one line.")
  cecho("\n  " .. V .. "Achaea default is " .. W .. ";;" .. V .. " but most use " .. W .. ";")
  cecho("\n\n  " .. HL .. "ataxia setup separator <sep>")
  hint("  e.g.: ataxia setup separator ;;")
  cecho("\n")
end

-- ═══════════════════════════════════════════════════════════════════════
-- WEAPONS
-- ═══════════════════════════════════════════════════════════════════════
function leviSetup.setupWeapons(rest)
  local cmd = rest:match("^(%S+)")
  local cmdRest = rest:match("^%S+%s+(.+)$") or ""

  -- ataxia setup weapons scan
  if cmd == "scan" then
    if ataxia.scanWeapons then
      ataxia.scanWeapons()
    else
      ataxiaEcho("Weapon detection not loaded.")
    end
    return
  end

  -- ataxia setup weapons confirm
  if cmd == "confirm" then
    if ataxia.confirmWeapons then
      ataxia.confirmWeapons()
    else
      ataxiaEcho("Weapon detection not loaded.")
    end
    return
  end

  -- ataxia setup weapons swap <slot1> <slot2>
  if cmd == "swap" then
    local s1, s2 = cmdRest:match("^(%S+)%s+(%S+)$")
    if s1 and s2 and ataxia.swapWeaponSlots then
      ataxia.swapWeaponSlots(s1, s2)
    else
      ataxiaEcho("Usage: " .. W .. "ataxia setup weapons swap <slot1> <slot2>")
    end
    return
  end

  -- ataxia setup weapons set <slot> <id>  (or legacy: ataxia setup weapons <slot> <id>)
  local slot, id
  if cmd == "set" then
    slot, id = cmdRest:match("^(%S+)%s+(%S+)$")
  else
    slot, id = rest:match("^(%S+)%s+(%S+)$")
  end

  if slot and id then
    -- Normalize legacy slot names
    if slot == "scim1" then slot = "weapon1" end
    if slot == "scim2" then slot = "weapon2" end
    if slot == "baxe" then slot = "battleaxe" end

    ataxia.settings.weapons = ataxia.settings.weapons or {}
    ataxia.settings.weapons[slot] = id

    -- Sync DWC config if loaded
    if infernalDWC and infernalDWC.config then
      if slot == "weapon1" then infernalDWC.config.weapon1 = id end
      if slot == "weapon2" then infernalDWC.config.weapon2 = id end
      if slot == "battleaxe" then infernalDWC.config.battleaxe = id end
    end
    if infernalGroupLock and infernalGroupLock.config then
      if slot == "weapon1" then infernalGroupLock.config.weapon1 = id end
      if slot == "weapon2" then infernalGroupLock.config.weapon2 = id end
    end
    if infernalDWC2L and infernalDWC2L.config then
      if slot == "weapon1" then infernalDWC2L.config.weapon1 = id end
      if slot == "weapon2" then infernalDWC2L.config.weapon2 = id end
      if slot == "battleaxe" then infernalDWC2L.config.battleaxe = id end
    end

    -- Also update pending scan suggestions if active
    if ataxia.setWeaponSlotPending then
      ataxia.setWeaponSlotPending(slot, id)
    end

    save()
    ataxiaEcho(slot .. " set to: " .. W .. id)
    return
  end

  -- No subcommand: show current weapons + help
  header("Weapon Configuration")

  local weapons = ataxia.settings.weapons or {}
  local allSlots = {"weapon1", "weapon2", "mstar1", "mstar2", "staff", "staff2",
    "battleaxe", "longsword", "warhammer", "bastard", "lash", "fang", "scythe",
    "dagger", "rapier", "bow", "daegger", "flail1", "flail2",
    "axe", "blackjack", "stiletto", "stiletto2", "stiletto3"}

  cecho("\n  " .. HL .. "Current weapon IDs:\n")
  local hasAny = false
  for _, s in ipairs(allSlots) do
    if weapons[s] then
      row(s, weapons[s])
      hasAny = true
    end
  end
  if not hasAny then
    cecho("\n  " .. D .. "(no weapons configured)")
  end

  cecho("\n\n  " .. V .. "Commands:")
  cecho("\n  " .. HL .. "ataxia setup weapons scan" .. D .. "            Auto-detect from WEAPONLIST")
  cecho("\n  " .. HL .. "ataxia setup weapons set <slot> <id>" .. D .. " Set a weapon slot")
  cecho("\n  " .. HL .. "ataxia setup weapons swap <s1> <s2>" .. D .. "  Swap two slots")
  cecho("\n  " .. HL .. "ataxia setup weapons confirm" .. D .. "         Save scan results")
  cecho("\n")
  cecho("\n  " .. D .. "Slots: weapon1, weapon2, mstar1, mstar2, staff, staff2,")
  cecho("\n  " .. D .. "       battleaxe, longsword, warhammer, bastard, lash, fang,")
  cecho("\n  " .. D .. "       scythe, dagger, rapier, bow, daegger, flail1, flail2,")
  cecho("\n  " .. D .. "       axe, blackjack, stiletto, stiletto2, stiletto3")
  hint("  e.g.: ataxia setup weapons set weapon1 scimitar405403")
  hint("  Recommended: ataxia setup weapons scan")
  cecho("\n")
end

-- ═══════════════════════════════════════════════════════════════════════
-- MOUNT
-- ═══════════════════════════════════════════════════════════════════════
function leviSetup.setupMount(rest)
  if rest and rest ~= "" then
    ataxia.settings.user = ataxia.settings.user or {}
    ataxia.settings.user.mount = rest
    save()
    ataxiaEcho("Mount set to: " .. W .. rest)
    return
  end

  header("Mount / Companion")

  local current = (ataxia.settings.user and ataxia.settings.user.mount) or "not set"
  row("Mount name", current)

  cecho("\n\n  " .. V .. "Set your mount/companion name:")
  cecho("\n  " .. HL .. "ataxia setup mount <name>")
  hint("  e.g.: ataxia setup mount impastus")
  hint("  Used by: flying, dragonform, urn, steed triggers")
  cecho("\n")
end

-- ═══════════════════════════════════════════════════════════════════════
-- ARTEFACTS
-- ═══════════════════════════════════════════════════════════════════════
function leviSetup.setupArtefacts(rest)
  local slot, id = rest:match("^(%S+)%s+(%S+)$")

  if slot and id then
    ataxia.settings.user = ataxia.settings.user or {}
    ataxia.settings.user.artefacts = ataxia.settings.user.artefacts or {}
    local validSlots = {pendant = true, bracelet = true, belt = true, ring = true}
    if validSlots[slot] then
      ataxia.settings.user.artefacts[slot] = id
      save()
      ataxiaEcho(slot .. " set to: " .. W .. id)
    else
      ataxiaEcho("Unknown artefact slot: " .. W .. slot)
      cecho("\n  " .. D .. "Valid slots: pendant, bracelet, belt, ring")
    end
    return
  end

  header("Artefact Configuration")

  local u = ataxia.settings.user or {}
  local a = u.artefacts or {}

  cecho("\n  " .. HL .. "Current artefact IDs:\n")
  row("pendant", a.pendant or "not set")
  row("bracelet", a.bracelet or "not set")
  row("belt", a.belt or "not set")
  row("ring", a.ring or "not set", "icewall ring")

  cecho("\n\n  " .. V .. "Set an artefact ID:")
  cecho("\n  " .. HL .. "ataxia setup artefacts <slot> <itemID>")
  hint("  e.g.: ataxia setup artefacts pendant pendant398551")
  hint("  e.g.: ataxia setup artefacts ring ring379683")
  hint("  Find IDs with: II pendant, II bracelet, etc.")
  cecho("\n")
end

-- ═══════════════════════════════════════════════════════════════════════
-- EARRINGS
-- ═══════════════════════════════════════════════════════════════════════
function leviSetup.setupEarrings(rest)
  if rest == "auto" then
    leviSetup.earringAutoStart()
    return
  end

  local location, id = rest:match("^(%S+)%s+(%S+)$")

  if location and id then
    ataxia.settings.user = ataxia.settings.user or {}
    ataxia.settings.user.artefacts = ataxia.settings.user.artefacts or {}
    ataxia.settings.user.artefacts.earrings = ataxia.settings.user.artefacts.earrings or {}
    ataxia.settings.user.artefacts.earrings[location] = id
    save()
    ataxiaEcho("Earring for " .. W .. location .. V .. " set to: " .. W .. id)
    return
  end

  header("Travel Earring Configuration")

  local u = ataxia.settings.user or {}
  local a = u.artefacts or {}
  local e = a.earrings or {}

  local locations = {"axios", "aegoth", "proficy", "pharaus", "zylvith",
    "antoninus", "entaro", "xarthus", "tabethys"}

  cecho("\n  " .. HL .. "Current earring assignments:\n")
  for _, loc in ipairs(locations) do
    row(loc, e[loc] or "not set")
  end

  cecho("\n\n  " .. V .. "Auto-configure all earrings:")
  cecho("\n  " .. HL .. "ataxia setup earrings auto")
  hint("  Sends EARRINGS command and auto-assigns all travel earrings")

  cecho("\n\n  " .. V .. "Set an earring manually:")
  cecho("\n  " .. HL .. "ataxia setup earrings <location> <earringID>")
  hint("  e.g.: ataxia setup earrings axios earring87118")
  hint("  e.g.: ataxia setup earrings aegoth earring244327")
  hint("  Find IDs with: II earring")
  cecho("\n")
end

-- ── earring auto-config ────────────────────────────────────────────────

local earringKnownLocations = {
  axios = true, aegoth = true, proficy = true, pharaus = true,
  zylvith = true, antoninus = true, entaro = true, xarthus = true,
  tabethys = true,
}

function leviSetup.earringAutoCleanup()
  local st = leviSetup.earringAuto
  if not st then return end
  for _, tid in ipairs(st.triggers or {}) do
    killTrigger(tid)
  end
  if st.endTimer then killTimer(st.endTimer) end
  if st.dcHandler then killAnonymousEventHandler(st.dcHandler) end
  leviSetup.earringAuto = nil
end

function leviSetup.earringAutoStart()
  if leviSetup.earringAuto then
    ataxiaEcho("Earring auto-config already in progress.")
    return
  end

  leviSetup.earringAuto = {
    triggers = {},
    results = {},
    endTimer = nil,
    dcHandler = nil,
  }

  local st = leviSetup.earringAuto

  -- Cleanup on disconnect
  st.dcHandler = registerAnonymousEventHandler("sysDisconnectionEvent", function()
    if leviSetup.earringAuto then
      leviSetup.earringAutoCleanup()
    end
  end, true)

  ataxiaEcho("Scanning earrings...")

  -- Capture EARRINGS output: "Earring#87118 (M) is paired with Axios."
  local capTrig = tempRegexTrigger(
    [[Earring#(\d+).*is paired with (\w+)\.]],
    function()
      if not leviSetup.earringAuto then return end
      local id = "earring" .. matches[2]
      local loc = matches[3]:lower()
      if earringKnownLocations[loc] then
        leviSetup.earringAuto.results[loc] = id
      end
      -- Reset end timer on each match
      if leviSetup.earringAuto.endTimer then killTimer(leviSetup.earringAuto.endTimer) end
      leviSetup.earringAuto.endTimer = tempTimer(2.0, function()
        leviSetup.earringAutoFinish()
      end)
    end
  )
  table.insert(st.triggers, capTrig)

  -- Timeout if no output at all
  st.endTimer = tempTimer(3.0, function()
    if leviSetup.earringAuto then
      leviSetup.earringAutoFinish()
    end
  end)

  send("EARRINGS", false)
end

function leviSetup.earringAutoFinish()
  local st = leviSetup.earringAuto
  if not st then return end

  -- Clean triggers
  for _, tid in ipairs(st.triggers) do
    killTrigger(tid)
  end
  st.triggers = {}
  if st.endTimer then killTimer(st.endTimer); st.endTimer = nil end

  -- Apply results
  local count = 0
  ataxia.settings.user = ataxia.settings.user or {}
  ataxia.settings.user.artefacts = ataxia.settings.user.artefacts or {}
  ataxia.settings.user.artefacts.earrings = ataxia.settings.user.artefacts.earrings or {}

  for loc, id in pairs(st.results) do
    ataxia.settings.user.artefacts.earrings[loc] = id
    count = count + 1
  end

  if count > 0 then
    save()
  end

  -- Display results
  header("Earring Auto-Configuration Results")

  local locations = {"axios", "aegoth", "proficy", "pharaus", "zylvith",
    "antoninus", "entaro", "xarthus", "tabethys"}

  if count > 0 then
    cecho("\n  " .. HL .. "Assigned " .. W .. count .. HL .. " earrings:\n")
    for _, loc in ipairs(locations) do
      if st.results[loc] then
        row(loc, st.results[loc])
      end
    end

    -- Show any locations still unset
    local missing = {}
    for _, loc in ipairs(locations) do
      if not st.results[loc] and not ataxia.settings.user.artefacts.earrings[loc] then
        table.insert(missing, loc)
      end
    end
    if #missing > 0 then
      cecho("\n\n  " .. D .. "Not found: " .. table.concat(missing, ", "))
    end
  else
    cecho("\n  " .. R .. "No earring locations detected.")
    hint("  Set manually: ataxia setup earrings <location> <earringID>")
  end

  cecho("\n")
  leviSetup.earringAutoCleanup()
end

-- ═══════════════════════════════════════════════════════════════════════
-- BASHER
-- ═══════════════════════════════════════════════════════════════════════
function leviSetup.setupBasher(rest)
  local key, val = rest:match("^(%S+)%s+(.+)$")

  if key and val then
    if key == "goldpack" or key == "gold" then
      ataxiaBasher.goldPack = val
      save()
      ataxiaEcho("Gold pack set to: " .. W .. val)
      return
    elseif key == "flee" then
      ataxiaBasher.fleeThreshold = tonumber(val)
      save()
      ataxiaEcho("Flee threshold set to: " .. W .. val .. " HP")
      return
    elseif key == "shieldpct" then
      ataxiaBasher.shieldThresholdPct = tonumber(val)
      save()
      ataxiaEcho("Shield threshold set to: " .. W .. val .. "%")
      return
    elseif key == "fleepct" then
      ataxiaBasher.fleeThresholdPct = tonumber(val)
      save()
      ataxiaEcho("Flee threshold %% set to: " .. W .. val .. "%")
      return
    elseif key == "shieldtimer" then
      ataxiaBasher.shieldTimerDefault = tonumber(val)
      save()
      ataxiaEcho("Default shield timer set to: " .. W .. val .. "s")
      return
    elseif key == "swap" then
      ataxiaBasher.shieldswap = (val == "on" or val == "true" or val == "yes")
      save()
      ataxiaEcho("Shield swap: " .. boolStr(ataxiaBasher.shieldswap))
      return
    elseif key == "autolearn" then
      ataxiaBasher.autoLearn = (val == "on" or val == "true" or val == "yes")
      save()
      ataxiaEcho("Auto-learn denizens: " .. boolStr(ataxiaBasher.autoLearn))
      return
    end
  end

  header("Basher Configuration")

  row("Gold pack", ataxiaBasher.goldPack or "not set", "container for gold")
  row("Flee threshold", ataxiaBasher.fleeThreshold or "not set", "HP value")
  row("Flee %", ataxiaBasher.fleeThresholdPct or 25, "HP %")
  row("Shield %", ataxiaBasher.shieldThresholdPct or 40, "HP %")
  row("Shield swap", boolStr(ataxiaBasher.shieldswap), "retarget on shielded mob")
  row("Shield timer", (ataxiaBasher.shieldTimerDefault or 3.1) .. "s", "default wait")
  row("Battlerage raze", boolStr(ataxiaBasher.rageraze), "use razing battlerage")
  row("Auto-learn", boolStr(ataxiaBasher.autoLearn), "add denizens to targetList on room entry")

  cecho("\n\n  " .. V .. "Set values:")
  cecho("\n  " .. HL .. "ataxia setup basher goldpack <packID>")
  cecho("\n  " .. HL .. "ataxia setup basher flee <hp>")
  cecho("\n  " .. HL .. "ataxia setup basher fleepct <percent>")
  cecho("\n  " .. HL .. "ataxia setup basher shieldpct <percent>")
  cecho("\n  " .. HL .. "ataxia setup basher shieldtimer <seconds>")
  cecho("\n  " .. HL .. "ataxia setup basher swap <on|off>")
  cecho("\n  " .. HL .. "ataxia setup basher autolearn <on|off>")
  hint("  e.g.: ataxia setup basher goldpack pack436363")
  hint("  e.g.: ataxia setup basher flee 2500")
  cecho("\n")
end

-- ═══════════════════════════════════════════════════════════════════════
-- SIPPING
-- ═══════════════════════════════════════════════════════════════════════
function leviSetup.setupSipping(rest)
  local key, val = rest:match("^(%S+)%s+(%S+)$")

  if key and val then
    local n = tonumber(val)
    if not n then
      ataxiaEcho(R .. "Value must be a number.")
      return
    end
    local sip = ataxia.settings.sipping
    if sip[key] ~= nil then
      sip[key] = n
      save()
      ataxiaEcho("Sipping " .. W .. key .. V .. " set to: " .. W .. n)
      return
    else
      ataxiaEcho(R .. "Unknown sipping key: " .. W .. key)
      return
    end
  end

  header("Sipping Thresholds")

  local sip = ataxia.settings.sipping or {}
  row("siphealth", (sip.siphealth or 80) .. "%", "sip health below this")
  row("sipmana", (sip.sipmana or 70) .. "%", "sip mana below this")
  row("mosshealth", (sip.mosshealth or 70) .. "%", "eat moss below this HP%")
  row("mossmana", (sip.mossmana or 60) .. "%", "eat moss below this mana%")
  row("usemoss", boolStr(sip.usemoss), "use moss at all")
  row("aeonhealth", (sip.aeonhealth or 40) .. "%", "sip health in aeon")
  row("aeonmana", (sip.aeonmana or 40) .. "%", "sip mana in aeon")
  row("manause", (sip.manause or 30) .. "%", "transmute mana floor")
  row("transmuteat", (sip.transmuteat or 70) .. "%", "transmute below this HP% (off sip bal)")
  row("transmuteto", (sip.transmuteto or 99) .. "%", "transmute until HP%")

  cecho("\n\n  " .. V .. "Set a threshold:")
  cecho("\n  " .. HL .. "ataxia setup sipping <key> <value>")
  hint("  e.g.: ataxia setup sipping siphealth 85")
  hint("  e.g.: ataxia setup sipping sipmana 75")
  cecho("\n")
end

-- ═══════════════════════════════════════════════════════════════════════
-- TRACKING
-- ═══════════════════════════════════════════════════════════════════════
function leviSetup.setupTracking(rest)
  header("Affliction Tracking System")

  row("Current system", "V3 (probability-based)")
  cecho("\n\n  " .. V .. "V3 affliction tracking is always active.")
  cecho("\n  " .. V .. "V2 has been removed — V2 stubs route to V3 automatically.")
  cecho("\n")
end

-- ═══════════════════════════════════════════════════════════════════════
-- COMBAT TOGGLES
-- ═══════════════════════════════════════════════════════════════════════
function leviSetup.setupCombat(rest)
  local key, val = rest:match("^(%S+)%s*(.*)$")

  if key then
    if key == "partyrelay" or key == "relay" then
      partyrelay = (val == "on" or val == "true" or val == "yes" or val == "")
      if val == "off" or val == "false" or val == "no" then partyrelay = false end
      ataxiaEcho("Party relay: " .. boolStr(partyrelay))
      return
    elseif key == "looting" then
      ataxia.settings.looting = (val == "on" or val == "true" or val == "yes" or val == "")
      if val == "off" or val == "false" or val == "no" then ataxia.settings.looting = false end
      save()
      ataxiaEcho("Auto-looting: " .. boolStr(ataxia.settings.looting))
      return
    elseif key == "gagclot" then
      ataxia.settings.gagclot = (val == "on" or val == "true" or val == "yes" or val == "")
      if val == "off" or val == "false" or val == "no" then ataxia.settings.gagclot = false end
      save()
      ataxiaEcho("Gag clot: " .. boolStr(ataxia.settings.gagclot))
      return
    elseif key == "gold" then
      ataxia.settings.goldcommand = (val ~= "" and val) or ataxia.settings.goldcommand
      save()
      ataxiaEcho("Gold command: " .. W .. (ataxia.settings.goldcommand or "not set"))
      return
    end
  end

  header("Combat Settings")

  row("Party relay", boolStr(partyrelay), "callouts to party")
  row("Auto-loot", boolStr(ataxia.settings.looting))
  row("Gag clot", boolStr(ataxia.settings.gagclot), "hide clot messages")
  row("Gold command", ataxia.settings.goldcommand or "get gold::put gold in pack")
  row("Auto-gallop", boolStr(ataxia.settings.autogallop))
  row("Aeon cmd block", boolStr(ataxia.settings.aeoncommandblock), "block commands in aeon")

  cecho("\n\n  " .. V .. "Toggle:")
  cecho("\n  " .. HL .. "ataxia setup combat partyrelay <on|off>")
  cecho("\n  " .. HL .. "ataxia setup combat looting <on|off>")
  cecho("\n  " .. HL .. "ataxia setup combat gagclot <on|off>")
  cecho("\n  " .. HL .. "ataxia setup combat gold <command>")
  hint("  e.g.: ataxia setup combat partyrelay on")
  cecho("\n")
end

-- ═══════════════════════════════════════════════════════════════════════
-- GUI
-- ═══════════════════════════════════════════════════════════════════════
function leviSetup.setupGui(rest)
  if rest == "on" or rest == "create" then
    ataxia.usegui = true
    if ataxiagui_Create then
      ataxiagui_Create()
      ataxiaEcho("Full Geyser GUI enabled. Restart Mudlet to apply.")
    else
      ataxiaEcho(R .. "GUI creation function not found.")
    end
    save()
    return
  elseif rest == "off" or rest == "destroy" then
    ataxia.usegui = false
    save()
    ataxiaEcho("Full Geyser GUI disabled. Restart Mudlet to fully remove.")
    return
  end

  header("GUI Configuration")

  row("Full Geyser GUI (ataxiagui)", boolStr(ataxia.usegui))

  cecho("\n\n  " .. V .. "The following windows always load on startup:")
  cecho("\n    " .. HL .. "Chat" .. V .. ", " .. HL .. "Map" .. V .. ", " .. HL .. "Bash Window" .. V .. ", " .. HL .. "Limb Counter" .. V .. ", " .. HL .. "Hunter")
  cecho("\n")
  cecho("\n  " .. V .. "The full Geyser GUI (borders, vitals bars, gauges) is separate:")
  cecho("\n  " .. HL .. "ataxia setup gui on" .. V .. "  — Enable full Geyser GUI")
  cecho("\n  " .. HL .. "ataxia setup gui off" .. V .. " — Disable full Geyser GUI (recommended)")
  cecho("\n")
end

-- ═══════════════════════════════════════════════════════════════════════
-- NDB
-- ═══════════════════════════════════════════════════════════════════════
function leviSetup.setupNdb(rest)
  local key, val = rest:match("^(%S+)%s+(.+)$")

  if key and val and ataxiaNDB and ataxiaNDB.highlighting then
    -- Allow setting city highlight colours
    local cities = {"Ashtan", "Cyrene", "Eleusis", "Hashan", "Mhaldor", "Targossas", "Enemies", "Rogues", "Underworld"}
    for _, city in ipairs(cities) do
      if key:lower() == city:lower() then
        ataxiaNDB.highlighting[city] = val
        save()
        ataxiaEcho(city .. " highlight set to: <" .. val .. ">" .. val)
        return
      end
    end
    if key == "highlight" then
      ataxiaNDB.highlightNames = (val == "on" or val == "true" or val == "yes")
      save()
      ataxiaEcho("Name highlighting: " .. boolStr(ataxiaNDB.highlightNames))
      return
    elseif key == "priority" then
      ataxiaNDB.highlightPriority = val
      save()
      ataxiaEcho("Highlight priority: " .. W .. val)
      return
    end
  end

  header("Name Database (NDB) Configuration")

  if ataxiaNDB and ataxiaNDB.highlighting then
    row("Highlighting", boolStr(ataxiaNDB.highlightNames))
    row("Priority", ataxiaNDB.highlightPriority or "city", "city or enemies")

    cecho("\n\n  " .. HL .. "  City colours:\n")
    for city, colour in pairs(ataxiaNDB.highlighting) do
      cecho("\n    <" .. colour .. ">" .. city .. W .. string.rep(" ", math.max(1, 14 - #city)) .. colour)
    end
  else
    cecho("\n  " .. R .. "NDB not loaded yet. Connect to Achaea first.")
  end

  cecho("\n\n  " .. V .. "Set a colour:")
  cecho("\n  " .. HL .. "ataxia setup ndb <city> <colour>")
  cecho("\n  " .. HL .. "ataxia setup ndb highlight <on|off>")
  cecho("\n  " .. HL .. "ataxia setup ndb priority <city|enemies>")
  hint("  e.g.: ataxia setup ndb Mhaldor red")
  hint("  e.g.: ataxia setup ndb Ashtan purple")
  cecho("\n")
end

-- ═══════════════════════════════════════════════════════════════════════
-- INSTALL (first-time setup)
-- ═══════════════════════════════════════════════════════════════════════
function leviSetup.setupInstall(rest)
  if rest == "ataxia" or rest == "at" then
    ataxiaEcho("Running " .. W .. "atinstall" .. V .. " — this will reset Ataxia system settings.")
    ataxiaEcho("Configures server-side curing, prompt, screen width, and loads defaults.")
    ataxiaEcho("Type " .. HL .. "atinstall" .. V .. " again within 5 seconds to confirm.")
    return
  elseif rest == "basher" or rest == "ab" then
    ataxiaEcho("Running " .. W .. "abinstall" .. V .. " — initialising basher system...")
    local defaults = {
      confOpt = {["True"] = true, yes = true, yep = true, y = true,
                 ["False"] = false, nope = false, no = false, n = false},
      enabled = false,
      manual = false,
      areabash = false,
      paused = false,
      shielded = false,
      targetList = {},
      ignore = {},
      dangerList = {},
      dangerCount = 5,
      fleeThreshold = 1000,
      noShieldBreak = {mobs = {}, threshold = 0},
      rageraze = false,
      autoLearn = true,
    }
    ataxiaBasher = ataxiaBasher or {}
    for k, v in pairs(defaults) do
      if ataxiaBasher[k] == nil then
        ataxiaBasher[k] = v
      end
    end
    ataxiaBasherPaths = ataxiaBasherPaths or {}
    ataxiaEcho("Bashing systems engaged and ready.")
    save()
    return
  elseif rest == "ndb" or rest == "an" then
    ataxiaEcho("Running " .. W .. "aninstall" .. V .. " — initialising Name Database...")
    if ataxiaNDB_Install then
      ataxiaNDB_Install()
      ataxiaEcho("NDB installed successfully.")
    else
      ataxiaEcho(R .. "NDB install function not loaded. Connect to Achaea first.")
    end
    return
  elseif rest == "all" then
    ataxiaEcho("Running full system install: Ataxia + Basher + NDB")
    cecho("\n")
    ataxiaEcho("Step 1: Ataxia core — type " .. HL .. "atinstall" .. V .. " twice (confirm within 5s)")
    leviSetup.setupInstall("basher")
    cecho("\n")
    leviSetup.setupInstall("ndb")
    return
  end

  header("First-Time Installation")

  cecho("\n  " .. V .. "LEVI has three subsystems that each need a one-time install.")
  cecho("\n  " .. V .. "Run these commands " .. W .. "after connecting to Achaea" .. V .. ":\n")

  cecho("\n  " .. HL .. "Step 1: " .. W .. "Core Combat System")
  cecho("\n  " .. V .. "  Command: " .. G .. "atinstall")
  cecho("\n  " .. D .. "  Configures server-side curing (priorities, sipping, batching),")
  cecho("\n  " .. D .. "  prompt format, screen width, and loads default Ataxia settings.")
  cecho("\n  " .. D .. "  You will be asked to confirm by typing atinstall again within 5s.")

  cecho("\n\n  " .. HL .. "Step 2: " .. W .. "Basher (Hunting System)")
  cecho("\n  " .. V .. "  Command: " .. G .. "abinstall")
  cecho("\n  " .. D .. "  Initialises the automated bashing tables (target lists, flee,")
  cecho("\n  " .. D .. "  shield timers). Supports 30 classes out of the box.")

  cecho("\n\n  " .. HL .. "Step 3: " .. W .. "Name Database (NDB)")
  cecho("\n  " .. V .. "  Command: " .. G .. "aninstall")
  cecho("\n  " .. D .. "  Sets up player tracking via the Achaea API. Enables city-based")
  cecho("\n  " .. D .. "  name highlighting, enemy tracking, and player notes.")

  cecho("\n\n  " .. V .. "Or run them from here:")
  cecho("\n  " .. HL .. "ataxia setup install all" .. V .. "     — Install basher + NDB (Ataxia still needs manual confirm)")
  cecho("\n  " .. HL .. "ataxia setup install ataxia" .. V .. "  — Guidance for atinstall")
  cecho("\n  " .. HL .. "ataxia setup install basher" .. V .. "  — Run abinstall directly")
  cecho("\n  " .. HL .. "ataxia setup install ndb" .. V .. "     — Run aninstall directly")

  cecho("\n\n  " .. D .. "After installing, use " .. HL .. "ataxia setup guide" .. D .. " to learn what to configure.")
  cecho("\n")
end

-- ═══════════════════════════════════════════════════════════════════════
-- GUIDE (post-install configuration walkthrough)
-- ═══════════════════════════════════════════════════════════════════════
function leviSetup.setupGuide(rest)
  if rest == "ataxia" or rest == "at" then
    leviSetup.guideAtaxia()
    return
  elseif rest == "basher" or rest == "bash" then
    leviSetup.guideBasher()
    return
  elseif rest == "ndb" then
    leviSetup.guideNdb()
    return
  end

  header("Configuration Guide")

  cecho("\n  " .. V .. "After installing, configure each subsystem to your playstyle.")
  cecho("\n  " .. V .. "Pick a section below to see what you can change:\n")

  cecho("\n  " .. HL .. "ataxia setup guide ataxia" .. V .. "  — Core system (separator, prompt, defences, highlights, etc.)")
  cecho("\n  " .. HL .. "ataxia setup guide basher" .. V .. "  — Hunting (target lists, flee, danger, gold, shields)")
  cecho("\n  " .. HL .. "ataxia setup guide ndb" .. V .. "     — Player database (city colours, enemy formatting, notes)")

  cecho("\n\n  " .. D .. "Or jump straight into any setting with " .. HL .. "ataxia setup <section>" .. D .. ".")
  cecho("\n")
end

-- ── Guide: Ataxia Core ────────────────────────────────────────────────
function leviSetup.guideAtaxia()
  header("Guide: Ataxia Core Configuration")

  cecho("\n  " .. HL .. "ESSENTIAL (do these first)" .. "\n")

  cecho("\n  " .. W .. "1. Command Separator")
  cecho("\n  " .. D .. "   Joins multiple commands into one line. Achaea default is ;; but most use ;")
  cecho("\n  " .. V .. "   Command:  " .. G .. "aconfig separator <sep>")
  cecho("\n  " .. V .. "   Wizard:   " .. G .. "ataxia setup separator <sep>")

  cecho("\n\n  " .. W .. "2. Toggle System On/Off")
  cecho("\n  " .. D .. "   Master toggle to pause all Ataxia processing.")
  cecho("\n  " .. V .. "   Command:  " .. G .. "pp")
  cecho("\n  " .. D .. "   (pp again to re-enable)")

  cecho("\n\n  " .. W .. "3. Custom Prompt")
  cecho("\n  " .. D .. "   Enable/disable the custom prompt overlay.")
  cecho("\n  " .. V .. "   Command:  " .. G .. "aconfig customprompt <on|off>")

  cecho("\n\n  " .. HL .. "DEFENCES" .. "\n")

  cecho("\n  " .. W .. "4. Defence Profiles (defup/keep)")
  cecho("\n  " .. D .. "   Set which defences to automatically maintain.")
  cecho("\n  " .. V .. "   Commands: " .. G .. "defup" .. V .. "          — Raise all kept defences")
  cecho("\n  " .. V .. "             " .. G .. "defadd <def>" .. V .. "   — Add defence to keep list")
  cecho("\n  " .. V .. "             " .. G .. "defremove <def>" .. V .. " — Remove from keep list")
  cecho("\n  " .. V .. "             " .. G .. "deflist" .. V .. "        — Show current keep list")

  cecho("\n\n  " .. W .. "5. Curing Priorities")
  cecho("\n  " .. D .. "   Reorder which afflictions get cured first.")
  cecho("\n  " .. V .. "   Command:  " .. G .. "aconfig prios" .. V .. " — View/set priorities")

  cecho("\n\n  " .. HL .. "DISPLAY & QUALITY OF LIFE" .. "\n")

  cecho("\n  " .. W .. "6. Item Highlighting")
  cecho("\n  " .. D .. "   Highlight specific items in room descriptions (like a fang).")
  cecho("\n  " .. V .. "   Command:  " .. G .. "aconfig highlight <item>")
  cecho("\n  " .. V .. "   Example:  " .. D .. "aconfig highlight fang")

  cecho("\n\n  " .. W .. "7. Sipping Thresholds")
  cecho("\n  " .. D .. "   Control when health/mana potions are sipped.")
  cecho("\n  " .. V .. "   Command:  " .. G .. "hh <percent>" .. V .. "  — Set health sip %")
  cecho("\n  " .. V .. "   Wizard:   " .. G .. "ataxia setup sipping")

  cecho("\n\n  " .. W .. "8. Room Shortening")
  cecho("\n  " .. D .. "   Shorten long room descriptions for a cleaner display.")
  cecho("\n  " .. V .. "   Command:  " .. G .. "aconfig roomshorten <on|off>")

  cecho("\n\n  " .. W .. "9. GUI Toggle")
  cecho("\n  " .. D .. "   Enable/disable the Ataxia GUI (map, gauges, chat tabs).")
  cecho("\n  " .. V .. "   Command:  " .. G .. "aconfig gui <on|off>")
  cecho("\n  " .. V .. "   Wizard:   " .. G .. "ataxia setup gui <on|off>")

  cecho("\n\n  " .. W .. "10. Raid Mode")
  cecho("\n  " .. D .. "    Toggles raid-specific behaviour (group curing, priority shifts).")
  cecho("\n  " .. V .. "    Command:  " .. G .. "aconfig raid <on|off>")

  cecho("\n\n  " .. W .. "11. Auto-Gallop")
  cecho("\n  " .. D .. "    Automatically gallop when moving with a mount.")
  cecho("\n  " .. V .. "    Command:  " .. G .. "aconfig gallop <on|off>")

  cecho("\n\n  " .. W .. "12. Gag Clotting")
  cecho("\n  " .. D .. "    Hide clot messages from the main output.")
  cecho("\n  " .. V .. "    Command:  " .. G .. "aconfig gagclot <on|off>")

  cecho("\n\n  " .. D .. "See all current values: " .. HL .. "ataxia setup status")
  cecho("\n")
end

-- ── Guide: Basher ─────────────────────────────────────────────────────
function leviSetup.guideBasher()
  header("Guide: Basher Configuration")

  cecho("\n  " .. HL .. "GETTING STARTED" .. "\n")

  cecho("\n  " .. W .. "1. Enable the Basher")
  cecho("\n  " .. D .. "   Toggle bashing on/off.")
  cecho("\n  " .. V .. "   Commands: " .. G .. "bash on" .. V .. " / " .. G .. "bash off")
  cecho("\n  " .. D .. "   Or use: " .. G .. "bash auto" .. V .. " for full auto-pathing (areabash)")

  cecho("\n\n  " .. W .. "2. Add Targets for an Area")
  cecho("\n  " .. D .. "   Tell the basher what to attack in the current area.")
  cecho("\n  " .. V .. "   Commands: " .. G .. "bash room" .. V .. "          — Add everything in this room")
  cecho("\n  " .. V .. "             " .. G .. "bash add <mob>" .. V .. "     — Add a specific mob")
  cecho("\n  " .. V .. "             " .. G .. "bash remove <mob>" .. V .. "  — Remove a mob")
  cecho("\n  " .. V .. "             " .. G .. "bash list" .. V .. "          — Show target list for this area")

  cecho("\n\n  " .. HL .. "SAFETY & FLEE" .. "\n")

  cecho("\n  " .. W .. "3. Flee Threshold")
  cecho("\n  " .. D .. "   HP percentage to trigger automatic flee.")
  cecho("\n  " .. V .. "   Command:  " .. G .. "bash threshold <hp>")
  cecho("\n  " .. V .. "   Wizard:   " .. G .. "ataxia setup basher flee <hp>")
  cecho("\n  " .. D .. "   Default: ~25% HP to flee, ~40% HP to shield")

  cecho("\n\n  " .. W .. "4. Danger Mobs")
  cecho("\n  " .. D .. "   Mark mobs as dangerous — basher flees if too many are present.")
  cecho("\n  " .. V .. "   Commands: " .. G .. "bash danger <mob>" .. V .. "   — Mark as dangerous")
  cecho("\n  " .. V .. "             " .. G .. "bash undanger <mob>" .. V .. " — Unmark")
  cecho("\n  " .. V .. "             " .. G .. "bash dangercount <n>" .. V .. " — Max dangerous mobs before flee")

  cecho("\n\n  " .. W .. "5. Ignore List")
  cecho("\n  " .. D .. "   NPCs the basher should never attack.")
  cecho("\n  " .. V .. "   Commands: " .. G .. "bash ignore <mob>" .. V .. "   — Add to ignore list")
  cecho("\n  " .. V .. "             " .. G .. "bash unignore <mob>" .. V .. " — Remove from ignore list")

  cecho("\n\n  " .. HL .. "QUALITY OF LIFE" .. "\n")

  cecho("\n  " .. W .. "6. Gold Pack")
  cecho("\n  " .. D .. "   Container for automatic gold pickup.")
  cecho("\n  " .. V .. "   Command:  " .. G .. "bash goldpack <packID>")
  cecho("\n  " .. V .. "   Wizard:   " .. G .. "ataxia setup basher goldpack <packID>")
  cecho("\n  " .. D .. "   Find your pack ID with: " .. G .. "IH" .. D .. " (inventory highlights)")

  cecho("\n\n  " .. W .. "7. Shield Swap")
  cecho("\n  " .. D .. "   Retarget to a different mob when current target shields.")
  cecho("\n  " .. V .. "   Command:  " .. G .. "aconfig shieldswap <on|off>")
  cecho("\n  " .. V .. "   Wizard:   " .. G .. "ataxia setup basher swap <on|off>")

  cecho("\n\n  " .. W .. "8. Shield Timer")
  cecho("\n  " .. D .. "   How long to wait before re-engaging a shielded mob.")
  cecho("\n  " .. V .. "   Command:  " .. G .. "bash shieldtimer <seconds>")
  cecho("\n  " .. V .. "   Wizard:   " .. G .. "ataxia setup basher shieldtimer <seconds>")

  cecho("\n\n  " .. W .. "9. Rageraze (Battlerage)")
  cecho("\n  " .. D .. "   Use razing battlerage abilities when available.")
  cecho("\n  " .. V .. "   Command:  " .. G .. "bash rageraze <on|off>")

  cecho("\n\n  " .. W .. "10. Tree Blackout")
  cecho("\n  " .. D .. "    Use tree tattoo during blackout to cure afflictions.")
  cecho("\n  " .. V .. "    Command:  " .. G .. "bash treeblackout <on|off>")

  cecho("\n\n  " .. W .. "11. Auto-Learn Denizens")
  cecho("\n  " .. D .. "    Automatically add room denizens to the area target list while bashing.")
  cecho("\n  " .. V .. "    Wizard:   " .. G .. "ataxia setup basher autolearn <on|off>")

  cecho("\n\n  " .. W .. "12. Class-Specific (Dragon)")
  cecho("\n  " .. D .. "    Dragon bashing options: jab, wot, incantation.")
  cecho("\n  " .. V .. "    Commands: " .. G .. "bash jab <on|off>")
  cecho("\n  " .. V .. "              " .. G .. "bash wot <on|off>")
  cecho("\n  " .. V .. "              " .. G .. "bash incant <on|off>")

  cecho("\n\n  " .. D .. "See all current values: " .. HL .. "ataxia setup basher")
  cecho("\n")
end

-- ── Guide: NDB ────────────────────────────────────────────────────────
function leviSetup.guideNdb()
  header("Guide: Name Database (NDB) Configuration")

  cecho("\n  " .. HL .. "HIGHLIGHTING" .. "\n")

  cecho("\n  " .. W .. "1. City Highlight Colours")
  cecho("\n  " .. D .. "   Each city's players are shown in a specific colour.")
  cecho("\n  " .. V .. "   Command:  " .. G .. "anhl <city> <colour>")
  cecho("\n  " .. V .. "   Wizard:   " .. G .. "ataxia setup ndb <city> <colour>")
  cecho("\n  " .. D .. "   Cities: Ashtan, Cyrene, Eleusis, Hashan, Mhaldor, Targossas")
  cecho("\n  " .. D .. "   Also: Enemies, Rogues, Underworld")
  cecho("\n  " .. V .. "   Example:  " .. D .. "anhl Mhaldor red")

  cecho("\n\n  " .. W .. "2. Toggle Highlighting")
  cecho("\n  " .. D .. "   Turn name highlighting on/off entirely.")
  cecho("\n  " .. V .. "   Command:  " .. G .. "anhl" .. V .. " (toggles)")

  cecho("\n\n  " .. W .. "3. Highlight Priority")
  cecho("\n  " .. D .. "   Whether enemy status or city determines highlight colour.")
  cecho("\n  " .. V .. "   Command:  " .. G .. "an prio <city|enemies>")
  cecho("\n  " .. V .. "   Wizard:   " .. G .. "ataxia setup ndb priority <city|enemies>")

  cecho("\n\n  " .. HL .. "ENEMY FORMATTING" .. "\n")

  cecho("\n  " .. W .. "4. Enemy Name Format")
  cecho("\n  " .. D .. "   How enemy names appear (bold, italic, underline).")
  cecho("\n  " .. V .. "   Commands: " .. G .. "aneh b" .. V .. " — bold")
  cecho("\n  " .. V .. "             " .. G .. "aneh i" .. V .. " — italic")
  cecho("\n  " .. V .. "             " .. G .. "aneh u" .. V .. " — underline")

  cecho("\n\n  " .. HL .. "PLAYER DATA" .. "\n")

  cecho("\n  " .. W .. "5. Player Notes")
  cecho("\n  " .. D .. "   Attach notes to specific players for reference.")
  cecho("\n  " .. V .. "   Commands: " .. G .. "an noteadd <name> <text>")
  cecho("\n  " .. V .. "             " .. G .. "an noteremove <name>")
  cecho("\n  " .. V .. "             " .. G .. "an noteshow <name>")

  cecho("\n\n  " .. W .. "6. Whois / Honours Lookup")
  cecho("\n  " .. D .. "   Quickly check a player's info from the database.")
  cecho("\n  " .. V .. "   Commands: " .. G .. "an <name>" .. V .. "      — Show stored player data")
  cecho("\n  " .. V .. "             " .. G .. "anw <name>" .. V .. "     — Whois lookup")

  cecho("\n\n  " .. W .. "7. Settings Display")
  cecho("\n  " .. D .. "   View all NDB settings at once.")
  cecho("\n  " .. V .. "   Command:  " .. G .. "anss")

  cecho("\n\n  " .. D .. "See current colours: " .. HL .. "ataxia setup ndb")
  cecho("\n")
end

-- ═══════════════════════════════════════════════════════════════════════
-- STATUS (overview of all settings)
-- ═══════════════════════════════════════════════════════════════════════
function leviSetup.showStatus()
  header("LEVI System Status")

  -- Class
  local detected = (gmcp and gmcp.Char and gmcp.Char.Status and gmcp.Char.Status.class) or nil
  cecho("\n  " .. HL .. "CLASS")
  row("Class", ataxia.settings.class or "Unknown")
  if detected then row("GMCP class", detected) end

  -- Separator
  cecho("\n\n  " .. HL .. "SYSTEM")
  row("Separator", ataxia.settings.separator or ";")
  row("Aff tracking", "V3")
  row("Full Geyser GUI", boolStr(ataxia.usegui))
  row("Party relay", boolStr(partyrelay))
  row("Auto-loot", boolStr(ataxia.settings.looting))

  -- Mount & Artefacts
  local u = ataxia.settings.user or {}
  cecho("\n\n  " .. HL .. "MOUNT / ARTEFACTS")
  row("Mount", u.mount or "not set")
  local a = u.artefacts or {}
  row("Pendant", a.pendant or "not set")
  row("Bracelet", a.bracelet or "not set")
  row("Belt", a.belt or "not set")
  row("Ring", a.ring or "not set")

  -- Weapons
  local weapons = ataxia.settings.weapons or {}
  cecho("\n\n  " .. HL .. "WEAPONS")
  local wSlots = {"weapon1", "weapon2", "mstar1", "mstar2", "staff", "staff2",
    "battleaxe", "longsword", "warhammer", "bastard", "lash", "fang"}
  for _, s in ipairs(wSlots) do
    if weapons[s] then row(s, weapons[s]) end
  end
  if not next(weapons) then row("(none)", "run: ataxia setup weapons scan") end

  -- Sipping
  local sip = ataxia.settings.sipping or {}
  cecho("\n\n  " .. HL .. "SIPPING")
  row("Health sip", (sip.siphealth or 80) .. "%")
  row("Mana sip", (sip.sipmana or 70) .. "%")
  row("Moss health", (sip.mosshealth or 70) .. "%")
  row("Use moss", boolStr(sip.usemoss))

  -- Basher
  cecho("\n\n  " .. HL .. "BASHER")
  row("Gold pack", ataxiaBasher.goldPack or "not set")
  row("Flee threshold", ataxiaBasher.fleeThreshold or "not set")
  row("Shield swap", boolStr(ataxiaBasher.shieldswap))
  row("Auto-learn", boolStr(ataxiaBasher.autoLearn))

  -- NDB
  if ataxiaNDB then
    cecho("\n\n  " .. HL .. "NDB")
    row("Highlighting", boolStr(ataxiaNDB.highlightNames))
    row("Priority", ataxiaNDB.highlightPriority or "city")
  end

  -- SLC
  if selfLimbDamage and selfLimbDamage.config then
    local slc = selfLimbDamage.config
    cecho("\n\n  " .. HL .. "SLC (Self Limb Counter)")
    row("Enabled", boolStr(slc.enabled))
    row("Auto Parry", boolStr(slc.autoParry))
    row("Parry Mode", slc.parryMode or "stand")
    row("Anti-Shikudo", boolStr(slc.antiShikudo))
    row("Auto Shield", boolStr(slc.autoShield))
    row("SSC Priority", boolStr(slc.sscPriority))
    row("Party Callout", boolStr(slc.partyCallout))
    row("Warning Alerts", boolStr(slc.warningAlerts))
    row("Critical Alerts", boolStr(slc.criticalAlerts))
    row("GUI Window", boolStr(slc.guiWindow))
  end

  hint("\n  Use 'ataxia setup <section>' for details on any section.")
  cecho("\n")
end

-- ═══════════════════════════════════════════════════════════════════════
-- SLC (Self Limb Counter)
-- ═══════════════════════════════════════════════════════════════════════
function leviSetup.setupSlc(rest)
  if not selfLimbDamage or not selfLimbDamage.config then
    ataxiaEcho("SLC not initialized. selfLimbDamage.config missing.")
    return
  end

  local cfg = selfLimbDamage.config

  local function slcToggle(key, label, val)
    if val == "on" then
      cfg[key] = true
      cecho("\n  " .. G .. label .. ": ON")
      save()
    elseif val == "off" then
      cfg[key] = false
      cecho("\n  " .. R .. label .. ": OFF")
      save()
    else
      cecho("\n  " .. V .. label .. ": " .. (cfg[key] and (G .. "ON") or (R .. "OFF")))
      cecho("\n  " .. D .. "Use: " .. HL .. "ataxia setup slc " .. key .. " <on|off>")
    end
  end

  if rest == "" then
    header("SLC — Self Limb Counter")
    cecho("\n  " .. V .. "Current configuration:\n")

    local toggles = {
      {"enabled",        "Master Toggle"},
      {"autoParry",      "Auto Parry"},
      {"autoShield",     "Auto Shield"},
      {"sscPriority",    "SSC Priority"},
      {"partyCallout",   "Party Callout"},
      {"warningAlerts",  "Warning Alerts (2 hit)"},
      {"criticalAlerts", "Critical Alerts (1 hit)"},
      {"guiWindow",      "GUI Window"},
      {"antiShikudo",    "Anti-Shikudo Parry"},
    }

    for i, t in ipairs(toggles) do
      local state = cfg[t[1]] and (G .. "ON") or (R .. "OFF")
      cecho("\n  " .. HL .. "[" .. i .. "] " .. V .. t[2])
      local pad = string.rep(" ", math.max(1, 24 - #t[2]))
      cecho(pad .. state)
    end

    cecho("\n\n  " .. V .. "Parry Mode: " .. HL .. (cfg.parryMode or "stand"))
    cecho("\n  " .. V .. "Warning Hits: " .. HL .. (cfg.warningHits or 2))
    cecho("\n  " .. V .. "Critical Hits: " .. HL .. (cfg.criticalHits or 1))

    cecho("\n\n  " .. D .. "Toggle features:")
    cecho("\n  " .. HL .. "ataxia setup slc <key> <on|off>")
    hint("  e.g.: ataxia setup slc autoShield on")
    cecho("\n  " .. D .. "Set parry mode:")
    cecho("\n  " .. HL .. "ataxia setup slc parry <stand|defend|manual|randomarm|randomleg>")
    cecho("\n  " .. D .. "Set thresholds:")
    cecho("\n  " .. HL .. "ataxia setup slc warning <hits>")
    cecho("\n  " .. HL .. "ataxia setup slc critical <hits>")
    cecho("\n")
    return
  end

  local key, val = rest:match("^(%S+)%s+(%S+)$")
  if not key then key = rest end

  -- Parry mode
  if key == "parry" then
    local validModes = {stand = true, defend = true, manual = true, randomarm = true, randomleg = true}
    if val and validModes[val] then
      cfg.parryMode = val
      ataxia.parry = val
      cecho("\n  " .. G .. "Parry mode set to: " .. HL .. val)
      save()
    else
      cecho("\n  " .. V .. "Current parry mode: " .. HL .. (cfg.parryMode or "stand"))
      cecho("\n  " .. D .. "Valid modes: stand, defend, manual, randomarm, randomleg")
    end
    return
  end

  -- Thresholds
  if key == "warning" and val then
    local n = tonumber(val)
    if n then cfg.warningHits = n; cecho("\n  " .. G .. "Warning hits set to: " .. n); save() end
    return
  end
  if key == "critical" and val then
    local n = tonumber(val)
    if n then cfg.criticalHits = n; cecho("\n  " .. G .. "Critical hits set to: " .. n); save() end
    return
  end

  -- Boolean toggles
  local boolKeys = {
    enabled = "Master Toggle", autoParry = "Auto Parry", autoShield = "Auto Shield",
    sscPriority = "SSC Priority", partyCallout = "Party Callout",
    warningAlerts = "Warning Alerts", criticalAlerts = "Critical Alerts",
    guiWindow = "GUI Window", antiShikudo = "Anti-Shikudo Parry",
  }

  if boolKeys[key] then
    slcToggle(key, boolKeys[key], val)
  else
    cecho("\n  " .. W .. "Unknown SLC setting: " .. key)
    cecho("\n  " .. D .. "Type " .. HL .. "ataxia setup slc" .. D .. " to see all options.")
  end
end
