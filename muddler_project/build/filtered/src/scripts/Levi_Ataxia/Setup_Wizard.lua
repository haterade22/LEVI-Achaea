---------------------------------------------------------------------------
-- LEVI Setup Wizard
-- Provides "levi setup" command for guided system configuration.
-- All settings are persisted via ataxia_saveSettings().
---------------------------------------------------------------------------

leviSetup = leviSetup or {}

-- â”€â”€ colour shortcuts â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
local H  = "<dark_orchid>"       -- header / divider
local HL = "<light_slate_blue>"  -- highlight / label
local V  = "<NavajoWhite>"       -- value text
local G  = "<green>"             -- enabled / good
local R  = "<red>"               -- disabled / bad
local W  = "<white>"             -- white
local D  = "<dim_grey>"          -- dim / hint

-- â”€â”€ helpers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

-- â”€â”€ dispatch â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
  elseif cmd == "status"     then leviSetup.showStatus()
  elseif cmd == "install"    then leviSetup.setupInstall(rest)
  elseif cmd == "guide"      then leviSetup.setupGuide(rest)
  else
    ataxiaEcho("Unknown setup command: " .. W .. cmd)
    cecho("\n  " .. V .. "Type " .. HL .. "levi setup" .. V .. " for a list of commands.")
  end
end

-- â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?
-- MAIN MENU
-- â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?
function leviSetup.showMenu()
  header("LEVI Setup Wizard")
  cecho("\n  " .. V .. "Configure your system with these commands:\n")

  local cmds = {
    {"levi setup class",     "Set your class (auto-detects from GMCP)"},
    {"levi setup separator", "Set command separator (currently: " .. (ataxia.settings.separator or ";") .. ")"},
    {"levi setup weapons",   "Configure weapon IDs for your class"},
    {"levi setup basher",    "Basher settings (flee, gold pack, etc.)"},
    {"levi setup sipping",   "Health/mana sip thresholds"},
    {"levi setup tracking",  "Affliction tracking system (V1/V2)"},
    {"levi setup combat",    "Combat toggles (partyrelay, looting, etc.)"},
    {"levi setup slc",       "Self Limb Counter (parry, shield, alerts, etc.)"},
    {"levi setup gui",       "Toggle the GUI on/off"},
    {"levi setup ndb",       "Name Database highlighting colours"},
    {"levi setup install",   "First-time install (atinstall, abinstall, aninstall)"},
    {"levi setup guide",     "Post-install config guide (ataxia, basher, ndb)"},
    {"levi setup status",    "Show all current settings at a glance"},
  }

  for _, c in ipairs(cmds) do
    cecho("\n  " .. HL .. c[1])
    local pad = string.rep(" ", math.max(1, 24 - #c[1]))
    cecho(pad .. D .. c[2])
  end

  hint("\n  Settings auto-save on disconnect. Manual save: levi setup save")
  cecho("\n")
end

-- â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?
-- CLASS SETUP
-- â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?
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
  cecho("\n  " .. HL .. "levi setup class <ClassName>")
  hint("  e.g.: levi setup class Infernal")

  if detected and detected ~= "Unknown" and detected ~= (ataxia.settings.class or "") then
    cecho("\n\n  " .. G .. "GMCP detected " .. W .. detected .. G .. ". To accept:")
    cecho("\n  " .. HL .. "levi setup class " .. detected)
  end

  cecho("\n\n  " .. D .. "Available: " .. table.concat(classes, ", "))
  cecho("\n")
end

-- â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?
-- SEPARATOR
-- â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?
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
  cecho("\n\n  " .. HL .. "levi setup separator <sep>")
  hint("  e.g.: levi setup separator ;;")
  cecho("\n")
end

-- â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?
-- WEAPONS
-- â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?
function leviSetup.setupWeapons(rest)
  -- Parse: levi setup weapons <slot> <id>
  local slot, id = rest:match("^(%S+)%s+(%S+)$")

  if slot and id then
    -- Knight DWC weapons
    if slot == "scim1" or slot == "weapon1" then
      if infernalDWC then infernalDWC.config.weapon1 = id end
      ataxia.settings.weapons = ataxia.settings.weapons or {}
      ataxia.settings.weapons.weapon1 = id
      save()
      ataxiaEcho("Weapon 1 (right hand) set to: " .. W .. id)
      return
    elseif slot == "scim2" or slot == "weapon2" then
      if infernalDWC then infernalDWC.config.weapon2 = id end
      ataxia.settings.weapons = ataxia.settings.weapons or {}
      ataxia.settings.weapons.weapon2 = id
      save()
      ataxiaEcho("Weapon 2 (left hand) set to: " .. W .. id)
      return
    elseif slot == "battleaxe" or slot == "baxe" then
      if infernalDWC then infernalDWC.config.battleaxe = id end
      ataxia.settings.weapons = ataxia.settings.weapons or {}
      ataxia.settings.weapons.battleaxe = id
      save()
      ataxiaEcho("Battleaxe set to: " .. W .. id)
      return
    elseif slot == "staff" then
      staff = id
      ataxia.settings.weapons = ataxia.settings.weapons or {}
      ataxia.settings.weapons.staff = id
      save()
      ataxiaEcho("Staff set to: " .. W .. id)
      return
    end
  end

  header("Weapon Configuration")

  local weapons = ataxia.settings.weapons or {}

  cecho("\n  " .. HL .. "Current weapon IDs:\n")
  row("weapon1 (right hand)", weapons.weapon1 or (infernalDWC and infernalDWC.config and infernalDWC.config.weapon1) or "not set")
  row("weapon2 (left hand)", weapons.weapon2 or (infernalDWC and infernalDWC.config and infernalDWC.config.weapon2) or "not set")
  row("battleaxe", weapons.battleaxe or (infernalDWC and infernalDWC.config and infernalDWC.config.battleaxe) or "not set")
  row("staff", weapons.staff or (type(staff) == "string" and staff) or "not set")

  cecho("\n\n  " .. V .. "Set a weapon ID:")
  cecho("\n  " .. HL .. "levi setup weapons <slot> <itemID>")
  cecho("\n")
  cecho("\n  " .. D .. "Slots: weapon1, weapon2, battleaxe, staff")
  hint("  e.g.: levi setup weapons weapon1 scimitar405403")
  hint("  e.g.: levi setup weapons battleaxe battleaxe590991")
  hint("  Find IDs with: IH (inventory highlights) or II (inventory)")
  cecho("\n")
end

-- â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?
-- BASHER
-- â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?
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

  cecho("\n\n  " .. V .. "Set values:")
  cecho("\n  " .. HL .. "levi setup basher goldpack <packID>")
  cecho("\n  " .. HL .. "levi setup basher flee <hp>")
  cecho("\n  " .. HL .. "levi setup basher fleepct <percent>")
  cecho("\n  " .. HL .. "levi setup basher shieldpct <percent>")
  cecho("\n  " .. HL .. "levi setup basher shieldtimer <seconds>")
  cecho("\n  " .. HL .. "levi setup basher swap <on|off>")
  hint("  e.g.: levi setup basher goldpack pack436363")
  hint("  e.g.: levi setup basher flee 2500")
  cecho("\n")
end

-- â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?
-- SIPPING
-- â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?
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
  row("manause", (sip.manause or 30) .. "%", "transmute mana threshold")
  row("transmuteto", (sip.transmuteto or 70) .. "%", "transmute until HP%")

  cecho("\n\n  " .. V .. "Set a threshold:")
  cecho("\n  " .. HL .. "levi setup sipping <key> <value>")
  hint("  e.g.: levi setup sipping siphealth 85")
  hint("  e.g.: levi setup sipping sipmana 75")
  cecho("\n")
end

-- â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?
-- TRACKING
-- â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?
function leviSetup.setupTracking(rest)
  if rest == "v2" or rest == "on" then
    ataxia.settings.useAffTrackingV2 = true
    save()
    ataxiaEcho("Affliction tracking V2: " .. G .. "ENABLED")
    return
  elseif rest == "v1" or rest == "off" then
    ataxia.settings.useAffTrackingV2 = false
    save()
    ataxiaEcho("Affliction tracking V2: " .. R .. "DISABLED" .. V .. " (using V1)")
    return
  end

  header("Affliction Tracking System")

  local v2 = ataxia.settings.useAffTrackingV2
  row("Current system", v2 and "V2 (certainty-based)" or "V1 (boolean)")
  row("V2 status", boolStr(v2))

  cecho("\n\n  " .. HL .. "V1" .. V .. " â€” Simple boolean tracking (target has/doesn't have aff)")
  cecho("\n  " .. HL .. "V2" .. V .. " â€” Certainty-based with stacking, random cure prediction,")
  cecho("\n       " .. V .. "backtracking, and third-party verification")

  cecho("\n\n  " .. V .. "Toggle:")
  cecho("\n  " .. HL .. "levi setup tracking v2" .. V .. " â€” Enable V2")
  cecho("\n  " .. HL .. "levi setup tracking v1" .. V .. " â€” Revert to V1")
  cecho("\n")
end

-- â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?
-- COMBAT TOGGLES
-- â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?
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
  cecho("\n  " .. HL .. "levi setup combat partyrelay <on|off>")
  cecho("\n  " .. HL .. "levi setup combat looting <on|off>")
  cecho("\n  " .. HL .. "levi setup combat gagclot <on|off>")
  cecho("\n  " .. HL .. "levi setup combat gold <command>")
  hint("  e.g.: levi setup combat partyrelay on")
  cecho("\n")
end

-- â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?
-- GUI
-- â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?
function leviSetup.setupGui(rest)
  if rest == "on" or rest == "create" then
    ataxia.usegui = true
    if ataxiagui_Create then
      ataxiagui_Create()
      ataxiaEcho("GUI created.")
    else
      ataxiaEcho(R .. "GUI creation function not found.")
    end
    save()
    return
  elseif rest == "off" or rest == "destroy" then
    ataxia.usegui = false
    save()
    ataxiaEcho("GUI disabled. Restart Mudlet to fully remove.")
    return
  end

  header("GUI Configuration")

  row("GUI enabled", boolStr(ataxia.usegui))

  cecho("\n\n  " .. V .. "Commands:")
  cecho("\n  " .. HL .. "levi setup gui on" .. V .. "  â€” Create/enable GUI")
  cecho("\n  " .. HL .. "levi setup gui off" .. V .. " â€” Disable GUI")
  cecho("\n")
end

-- â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?
-- NDB
-- â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?
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
  cecho("\n  " .. HL .. "levi setup ndb <city> <colour>")
  cecho("\n  " .. HL .. "levi setup ndb highlight <on|off>")
  cecho("\n  " .. HL .. "levi setup ndb priority <city|enemies>")
  hint("  e.g.: levi setup ndb Mhaldor red")
  hint("  e.g.: levi setup ndb Ashtan purple")
  cecho("\n")
end

-- â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?
-- INSTALL (first-time setup)
-- â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?
function leviSetup.setupInstall(rest)
  if rest == "ataxia" or rest == "at" then
    ataxiaEcho("Running " .. W .. "atinstall" .. V .. " â€” this will reset Ataxia system settings.")
    ataxiaEcho("Configures server-side curing, prompt, screen width, and loads defaults.")
    ataxiaEcho("Type " .. HL .. "atinstall" .. V .. " again within 5 seconds to confirm.")
    return
  elseif rest == "basher" or rest == "ab" then
    ataxiaEcho("Running " .. W .. "abinstall" .. V .. " â€” initialising basher system...")
    ataxiaBasher = {}
    ataxiaBasher = {
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
    }
    ataxiaBasherPaths = {}
    ataxiaEcho("Bashing systems engaged and ready.")
    save()
    return
  elseif rest == "ndb" or rest == "an" then
    ataxiaEcho("Running " .. W .. "aninstall" .. V .. " â€” initialising Name Database...")
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
    ataxiaEcho("Step 1: Ataxia core â€” type " .. HL .. "atinstall" .. V .. " twice (confirm within 5s)")
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
  cecho("\n  " .. HL .. "levi setup install all" .. V .. "     â€” Install basher + NDB (Ataxia still needs manual confirm)")
  cecho("\n  " .. HL .. "levi setup install ataxia" .. V .. "  â€” Guidance for atinstall")
  cecho("\n  " .. HL .. "levi setup install basher" .. V .. "  â€” Run abinstall directly")
  cecho("\n  " .. HL .. "levi setup install ndb" .. V .. "     â€” Run aninstall directly")

  cecho("\n\n  " .. D .. "After installing, use " .. HL .. "levi setup guide" .. D .. " to learn what to configure.")
  cecho("\n")
end

-- â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?
-- GUIDE (post-install configuration walkthrough)
-- â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?
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

  cecho("\n  " .. HL .. "levi setup guide ataxia" .. V .. "  â€” Core system (separator, prompt, defences, highlights, etc.)")
  cecho("\n  " .. HL .. "levi setup guide basher" .. V .. "  â€” Hunting (target lists, flee, danger, gold, shields)")
  cecho("\n  " .. HL .. "levi setup guide ndb" .. V .. "     â€” Player database (city colours, enemy formatting, notes)")

  cecho("\n\n  " .. D .. "Or jump straight into any setting with " .. HL .. "levi setup <section>" .. D .. ".")
  cecho("\n")
end

-- â”€â”€ Guide: Ataxia Core â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
function leviSetup.guideAtaxia()
  header("Guide: Ataxia Core Configuration")

  cecho("\n  " .. HL .. "ESSENTIAL (do these first)" .. "\n")

  cecho("\n  " .. W .. "1. Command Separator")
  cecho("\n  " .. D .. "   Joins multiple commands into one line. Achaea default is ;; but most use ;")
  cecho("\n  " .. V .. "   Command:  " .. G .. "aconfig separator <sep>")
  cecho("\n  " .. V .. "   Wizard:   " .. G .. "levi setup separator <sep>")

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
  cecho("\n  " .. V .. "   Commands: " .. G .. "defup" .. V .. "          â€” Raise all kept defences")
  cecho("\n  " .. V .. "             " .. G .. "defadd <def>" .. V .. "   â€” Add defence to keep list")
  cecho("\n  " .. V .. "             " .. G .. "defremove <def>" .. V .. " â€” Remove from keep list")
  cecho("\n  " .. V .. "             " .. G .. "deflist" .. V .. "        â€” Show current keep list")

  cecho("\n\n  " .. W .. "5. Curing Priorities")
  cecho("\n  " .. D .. "   Reorder which afflictions get cured first.")
  cecho("\n  " .. V .. "   Command:  " .. G .. "aconfig prios" .. V .. " â€” View/set priorities")

  cecho("\n\n  " .. HL .. "DISPLAY & QUALITY OF LIFE" .. "\n")

  cecho("\n  " .. W .. "6. Item Highlighting")
  cecho("\n  " .. D .. "   Highlight specific items in room descriptions (like a fang).")
  cecho("\n  " .. V .. "   Command:  " .. G .. "aconfig highlight <item>")
  cecho("\n  " .. V .. "   Example:  " .. D .. "aconfig highlight fang")

  cecho("\n\n  " .. W .. "7. Sipping Thresholds")
  cecho("\n  " .. D .. "   Control when health/mana potions are sipped.")
  cecho("\n  " .. V .. "   Command:  " .. G .. "hh <percent>" .. V .. "  â€” Set health sip %")
  cecho("\n  " .. V .. "   Wizard:   " .. G .. "levi setup sipping")

  cecho("\n\n  " .. W .. "8. Room Shortening")
  cecho("\n  " .. D .. "   Shorten long room descriptions for a cleaner display.")
  cecho("\n  " .. V .. "   Command:  " .. G .. "aconfig roomshorten <on|off>")

  cecho("\n\n  " .. W .. "9. GUI Toggle")
  cecho("\n  " .. D .. "   Enable/disable the Ataxia GUI (map, gauges, chat tabs).")
  cecho("\n  " .. V .. "   Command:  " .. G .. "aconfig gui <on|off>")
  cecho("\n  " .. V .. "   Wizard:   " .. G .. "levi setup gui <on|off>")

  cecho("\n\n  " .. W .. "10. Raid Mode")
  cecho("\n  " .. D .. "    Toggles raid-specific behaviour (group curing, priority shifts).")
  cecho("\n  " .. V .. "    Command:  " .. G .. "aconfig raid <on|off>")

  cecho("\n\n  " .. W .. "11. Auto-Gallop")
  cecho("\n  " .. D .. "    Automatically gallop when moving with a mount.")
  cecho("\n  " .. V .. "    Command:  " .. G .. "aconfig gallop <on|off>")

  cecho("\n\n  " .. W .. "12. Gag Clotting")
  cecho("\n  " .. D .. "    Hide clot messages from the main output.")
  cecho("\n  " .. V .. "    Command:  " .. G .. "aconfig gagclot <on|off>")

  cecho("\n\n  " .. D .. "See all current values: " .. HL .. "levi setup status")
  cecho("\n")
end

-- â”€â”€ Guide: Basher â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
function leviSetup.guideBasher()
  header("Guide: Basher Configuration")

  cecho("\n  " .. HL .. "GETTING STARTED" .. "\n")

  cecho("\n  " .. W .. "1. Enable the Basher")
  cecho("\n  " .. D .. "   Toggle bashing on/off.")
  cecho("\n  " .. V .. "   Commands: " .. G .. "bash on" .. V .. " / " .. G .. "bash off")
  cecho("\n  " .. D .. "   Or use: " .. G .. "bash auto" .. V .. " for full auto-pathing (areabash)")

  cecho("\n\n  " .. W .. "2. Add Targets for an Area")
  cecho("\n  " .. D .. "   Tell the basher what to attack in the current area.")
  cecho("\n  " .. V .. "   Commands: " .. G .. "bash room" .. V .. "          â€” Add everything in this room")
  cecho("\n  " .. V .. "             " .. G .. "bash add <mob>" .. V .. "     â€” Add a specific mob")
  cecho("\n  " .. V .. "             " .. G .. "bash remove <mob>" .. V .. "  â€” Remove a mob")
  cecho("\n  " .. V .. "             " .. G .. "bash list" .. V .. "          â€” Show target list for this area")

  cecho("\n\n  " .. HL .. "SAFETY & FLEE" .. "\n")

  cecho("\n  " .. W .. "3. Flee Threshold")
  cecho("\n  " .. D .. "   HP percentage to trigger automatic flee.")
  cecho("\n  " .. V .. "   Command:  " .. G .. "bash threshold <hp>")
  cecho("\n  " .. V .. "   Wizard:   " .. G .. "levi setup basher flee <hp>")
  cecho("\n  " .. D .. "   Default: ~25% HP to flee, ~40% HP to shield")

  cecho("\n\n  " .. W .. "4. Danger Mobs")
  cecho("\n  " .. D .. "   Mark mobs as dangerous â€” basher flees if too many are present.")
  cecho("\n  " .. V .. "   Commands: " .. G .. "bash danger <mob>" .. V .. "   â€” Mark as dangerous")
  cecho("\n  " .. V .. "             " .. G .. "bash undanger <mob>" .. V .. " â€” Unmark")
  cecho("\n  " .. V .. "             " .. G .. "bash dangercount <n>" .. V .. " â€” Max dangerous mobs before flee")

  cecho("\n\n  " .. W .. "5. Ignore List")
  cecho("\n  " .. D .. "   NPCs the basher should never attack.")
  cecho("\n  " .. V .. "   Commands: " .. G .. "bash ignore <mob>" .. V .. "   â€” Add to ignore list")
  cecho("\n  " .. V .. "             " .. G .. "bash unignore <mob>" .. V .. " â€” Remove from ignore list")

  cecho("\n\n  " .. HL .. "QUALITY OF LIFE" .. "\n")

  cecho("\n  " .. W .. "6. Gold Pack")
  cecho("\n  " .. D .. "   Container for automatic gold pickup.")
  cecho("\n  " .. V .. "   Command:  " .. G .. "bash goldpack <packID>")
  cecho("\n  " .. V .. "   Wizard:   " .. G .. "levi setup basher goldpack <packID>")
  cecho("\n  " .. D .. "   Find your pack ID with: " .. G .. "IH" .. D .. " (inventory highlights)")

  cecho("\n\n  " .. W .. "7. Shield Swap")
  cecho("\n  " .. D .. "   Retarget to a different mob when current target shields.")
  cecho("\n  " .. V .. "   Command:  " .. G .. "aconfig shieldswap <on|off>")
  cecho("\n  " .. V .. "   Wizard:   " .. G .. "levi setup basher swap <on|off>")

  cecho("\n\n  " .. W .. "8. Shield Timer")
  cecho("\n  " .. D .. "   How long to wait before re-engaging a shielded mob.")
  cecho("\n  " .. V .. "   Command:  " .. G .. "bash shieldtimer <seconds>")
  cecho("\n  " .. V .. "   Wizard:   " .. G .. "levi setup basher shieldtimer <seconds>")

  cecho("\n\n  " .. W .. "9. Rageraze (Battlerage)")
  cecho("\n  " .. D .. "   Use razing battlerage abilities when available.")
  cecho("\n  " .. V .. "   Command:  " .. G .. "bash rageraze <on|off>")

  cecho("\n\n  " .. W .. "10. Tree Blackout")
  cecho("\n  " .. D .. "    Use tree tattoo during blackout to cure afflictions.")
  cecho("\n  " .. V .. "    Command:  " .. G .. "bash treeblackout <on|off>")

  cecho("\n\n  " .. W .. "11. Class-Specific (Dragon)")
  cecho("\n  " .. D .. "    Dragon bashing options: jab, wot, incantation.")
  cecho("\n  " .. V .. "    Commands: " .. G .. "bash jab <on|off>")
  cecho("\n  " .. V .. "              " .. G .. "bash wot <on|off>")
  cecho("\n  " .. V .. "              " .. G .. "bash incant <on|off>")

  cecho("\n\n  " .. D .. "See all current values: " .. HL .. "levi setup basher")
  cecho("\n")
end

-- â”€â”€ Guide: NDB â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
function leviSetup.guideNdb()
  header("Guide: Name Database (NDB) Configuration")

  cecho("\n  " .. HL .. "HIGHLIGHTING" .. "\n")

  cecho("\n  " .. W .. "1. City Highlight Colours")
  cecho("\n  " .. D .. "   Each city's players are shown in a specific colour.")
  cecho("\n  " .. V .. "   Command:  " .. G .. "anhl <city> <colour>")
  cecho("\n  " .. V .. "   Wizard:   " .. G .. "levi setup ndb <city> <colour>")
  cecho("\n  " .. D .. "   Cities: Ashtan, Cyrene, Eleusis, Hashan, Mhaldor, Targossas")
  cecho("\n  " .. D .. "   Also: Enemies, Rogues, Underworld")
  cecho("\n  " .. V .. "   Example:  " .. D .. "anhl Mhaldor red")

  cecho("\n\n  " .. W .. "2. Toggle Highlighting")
  cecho("\n  " .. D .. "   Turn name highlighting on/off entirely.")
  cecho("\n  " .. V .. "   Command:  " .. G .. "anhl" .. V .. " (toggles)")

  cecho("\n\n  " .. W .. "3. Highlight Priority")
  cecho("\n  " .. D .. "   Whether enemy status or city determines highlight colour.")
  cecho("\n  " .. V .. "   Command:  " .. G .. "an prio <city|enemies>")
  cecho("\n  " .. V .. "   Wizard:   " .. G .. "levi setup ndb priority <city|enemies>")

  cecho("\n\n  " .. HL .. "ENEMY FORMATTING" .. "\n")

  cecho("\n  " .. W .. "4. Enemy Name Format")
  cecho("\n  " .. D .. "   How enemy names appear (bold, italic, underline).")
  cecho("\n  " .. V .. "   Commands: " .. G .. "aneh b" .. V .. " â€” bold")
  cecho("\n  " .. V .. "             " .. G .. "aneh i" .. V .. " â€” italic")
  cecho("\n  " .. V .. "             " .. G .. "aneh u" .. V .. " â€” underline")

  cecho("\n\n  " .. HL .. "PLAYER DATA" .. "\n")

  cecho("\n  " .. W .. "5. Player Notes")
  cecho("\n  " .. D .. "   Attach notes to specific players for reference.")
  cecho("\n  " .. V .. "   Commands: " .. G .. "an noteadd <name> <text>")
  cecho("\n  " .. V .. "             " .. G .. "an noteremove <name>")
  cecho("\n  " .. V .. "             " .. G .. "an noteshow <name>")

  cecho("\n\n  " .. W .. "6. Whois / Honours Lookup")
  cecho("\n  " .. D .. "   Quickly check a player's info from the database.")
  cecho("\n  " .. V .. "   Commands: " .. G .. "an <name>" .. V .. "      â€” Show stored player data")
  cecho("\n  " .. V .. "             " .. G .. "anw <name>" .. V .. "     â€” Whois lookup")

  cecho("\n\n  " .. W .. "7. Settings Display")
  cecho("\n  " .. D .. "   View all NDB settings at once.")
  cecho("\n  " .. V .. "   Command:  " .. G .. "anss")

  cecho("\n\n  " .. D .. "See current colours: " .. HL .. "levi setup ndb")
  cecho("\n")
end

-- â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?
-- STATUS (overview of all settings)
-- â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?
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
  row("Aff tracking", ataxia.settings.useAffTrackingV2 and "V2" or "V1")
  row("GUI", boolStr(ataxia.usegui))
  row("Party relay", boolStr(partyrelay))
  row("Auto-loot", boolStr(ataxia.settings.looting))

  -- Weapons
  local weapons = ataxia.settings.weapons or {}
  cecho("\n\n  " .. HL .. "WEAPONS")
  row("weapon1", weapons.weapon1 or "not set")
  row("weapon2", weapons.weapon2 or "not set")
  row("battleaxe", weapons.battleaxe or "not set")

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

  hint("\n  Use 'levi setup <section>' for details on any section.")
  cecho("\n")
end

-- â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?
-- SLC (Self Limb Counter)
-- â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?â•?
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
      cecho("\n  " .. D .. "Use: " .. HL .. "levi setup slc " .. key .. " <on|off>")
    end
  end

  if rest == "" then
    header("SLC â€” Self Limb Counter")
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
    cecho("\n  " .. HL .. "levi setup slc <key> <on|off>")
    hint("  e.g.: levi setup slc autoShield on")
    cecho("\n  " .. D .. "Set parry mode:")
    cecho("\n  " .. HL .. "levi setup slc parry <stand|defend|manual|randomarm|randomleg>")
    cecho("\n  " .. D .. "Set thresholds:")
    cecho("\n  " .. HL .. "levi setup slc warning <hits>")
    cecho("\n  " .. HL .. "levi setup slc critical <hits>")
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
    cecho("\n  " .. D .. "Type " .. HL .. "levi setup slc" .. D .. " to see all options.")
  end
end
